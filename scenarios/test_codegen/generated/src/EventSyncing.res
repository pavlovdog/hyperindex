let queryEventsWithCombinedFilterAndProcessEventBatch = async (
  ~addressInterfaceMapping,
  ~eventFilters,
  ~fromBlock,
  ~toBlock,
  ~blockLoader,
  ~provider,
  ~chainConfig: Config.chainConfig,
) => {
  let events = await EventFetching.queryEventsWithCombinedFilter(
    ~addressInterfaceMapping,
    ~eventFilters,
    ~fromBlock,
    ~toBlock,
    ~blockLoader,
    ~provider,
    ~chainId=chainConfig.chainId,
    (),
  )
  events->EventProcessing.processEventBatch(
    ~chainConfig,
    ~blockLoader,
    ~blocksProcessed={from: fromBlock, to: toBlock},
  )
}

let processAllEventsFromBlockNumber = async (
  ~fromBlock: int,
  ~blockInterval as maxBlockInterval,
  ~chainConfig: Config.chainConfig,
  ~provider,
  ~blockLoader,
) => {
  let addressInterfaceMapping: Js.Dict.t<Ethers.Interface.t> = Js.Dict.empty()

  let eventFilters = EventFetching.getAllEventFilters(
    ~addressInterfaceMapping,
    ~chainConfig,
    ~provider,
  )

  let fromBlockRef = ref(fromBlock)

  let getCurrentBlockFromRPC = () =>
    provider
    ->Ethers.JsonRpcProvider.getBlockNumber
    ->Promise.catch(_err => {
      Logging.warn("Error getting current block number")
      0->Promise.resolve
    })
  let currentBlock: ref<int> = ref(await getCurrentBlockFromRPC())

  //we retrieve the latest processed block from the db and add 1
  //if only one block has occurred since that processed block we ensure that the new block
  //is handled with the below condition
  let shouldContinueProcess = () => fromBlockRef.contents <= currentBlock.contents

  while shouldContinueProcess() {
    let targetBlock = Pervasives.min(
      currentBlock.contents,
      fromBlockRef.contents + maxBlockInterval - 1,
    )

    let (events, blocksProcessed) = await EventFetching.getContractEventsOnFilters(
      ~addressInterfaceMapping,
      ~eventFilters,
      ~minFromBlockLogIndex=0,
      ~fromBlock=fromBlockRef.contents,
      ~toBlock=targetBlock,
      ~maxBlockInterval,
      ~chainId=chainConfig.chainId,
      ~provider,
      ~blockLoader,
      (),
    )

    //process the batch of events
    //NOTE: we can use this to track batch processing time
    await events->EventProcessing.processEventBatch(~chainConfig, ~blockLoader, ~blocksProcessed)

    fromBlockRef := blocksProcessed.to + 1
    currentBlock := (await getCurrentBlockFromRPC())
  }
}

let processAllEvents = async (chainConfig: Config.chainConfig) => {
  let blockLoader = LazyLoader.make(
    ~loaderFn=EventFetching.getUnwrappedBlock(chainConfig.provider),
    (),
  )
  let latestProcessedBlock = await DbFunctions.RawEvents.getLatestProcessedBlockNumber(
    ~chainId=chainConfig.chainId,
  )

  let startBlock =
    latestProcessedBlock->Belt.Option.mapWithDefault(chainConfig.startBlock, latestProcessedBlock =>
      latestProcessedBlock + 1
    )

  //Add all contracts and addresses from config
  Converters.ContractNameAddressMappings.registerStaticAddresses(~chainConfig)

  //Add all dynamic contracts from DB
  let dynamicContracts =
    await DbFunctions.sql->DbFunctions.DynamicContractRegistry.readDynamicContractsOnChainIdAtOrBeforeBlock(
      ~chainId=chainConfig.chainId,
      ~startBlock,
    )

  dynamicContracts->Belt.Array.forEach(({contractType, contractAddress}) =>
    Converters.ContractNameAddressMappings.addContractAddress(
      ~chainId=chainConfig.chainId,
      ~contractName=contractType,
      ~contractAddress,
    )
  )

  await processAllEventsFromBlockNumber(
    ~fromBlock=startBlock,
    ~chainConfig,
    ~blockInterval=Config.syncConfig.initialBlockInterval,
    ~provider=chainConfig.provider,
    ~blockLoader,
  )
}

let startSyncingAllEvents = () => {
  Config.config
  ->Js.Dict.values
  ->Belt.Array.map(chainConfig => {
    chainConfig->processAllEvents
  })
  ->Promise.all
  ->Promise.thenResolve(_ => ())
}
