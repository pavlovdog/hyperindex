//*************
//***ENTITIES**
//*************

@spice @genType.as("Id")
type id = string

//nested subrecord types

@@warning("-30")
@genType
type rec userLoaderConfig = {loadGravatar?: gravatarLoaderConfig, loadTokens?: tokenLoaderConfig}
and gravatarLoaderConfig = {loadOwner?: userLoaderConfig}
and nftcollectionLoaderConfig = bool
and tokenLoaderConfig = {loadCollection?: nftcollectionLoaderConfig, loadOwner?: userLoaderConfig}
and aLoaderConfig = {loadB?: bLoaderConfig}
and bLoaderConfig = {loadA?: aLoaderConfig, loadC?: cLoaderConfig}
and cLoaderConfig = {loadA?: aLoaderConfig}

@@warning("+30")

type entityRead =
  | UserRead(id, userLoaderConfig)
  | GravatarRead(id, gravatarLoaderConfig)
  | NftcollectionRead(id)
  | TokenRead(id, tokenLoaderConfig)
  | ARead(id, aLoaderConfig)
  | BRead(id, bLoaderConfig)
  | CRead(id, cLoaderConfig)

let entitySerialize = (entity: entityRead) => {
  switch entity {
  | UserRead(id, _) => `user${id}`
  | GravatarRead(id, _) => `gravatar${id}`
  | NftcollectionRead(id) => `nftcollection${id}`
  | TokenRead(id, _) => `token${id}`
  | ARead(id, _) => `a${id}`
  | BRead(id, _) => `b${id}`
  | CRead(id, _) => `c${id}`
  }
}

type rawEventsEntity = {
  @as("chain_id") chainId: int,
  @as("event_id") eventId: string,
  @as("block_number") blockNumber: int,
  @as("log_index") logIndex: int,
  @as("transaction_index") transactionIndex: int,
  @as("transaction_hash") transactionHash: string,
  @as("src_address") srcAddress: Ethers.ethAddress,
  @as("block_hash") blockHash: string,
  @as("block_timestamp") blockTimestamp: int,
  @as("event_type") eventType: Js.Json.t,
  params: string,
}

type dynamicContractRegistryEntity = {
  @as("chain_id") chainId: int,
  @as("event_id") eventId: Ethers.BigInt.t,
  @as("contract_address") contractAddress: Ethers.ethAddress,
  @as("contract_type") contractType: string,
}

@spice @genType
type userEntity = {
  id: string,
  address: string,
  gravatar?: id,
  updatesCountOnUserForTesting: int,
  tokens: array<id>,
}

@spice @genType
type gravatarEntity = {
  id: string,
  owner: id,
  displayName: string,
  imageUrl: string,
  updatesCount: Ethers.BigInt.t,
}

@spice @genType
type nftcollectionEntity = {
  id: string,
  contractAddress: string,
  name: string,
  symbol: string,
  maxSupply: Ethers.BigInt.t,
  currentSupply: int,
}

@spice @genType
type tokenEntity = {
  id: string,
  tokenId: Ethers.BigInt.t,
  collection: id,
  owner: id,
}

@spice @genType
type aEntity = {
  id: string,
  b: id,
}

@spice @genType
type bEntity = {
  id: string,
  a: array<id>,
  c?: id,
}

@spice @genType
type cEntity = {
  id: string,
  a: id,
}

type entity =
  | UserEntity(userEntity)
  | GravatarEntity(gravatarEntity)
  | NftcollectionEntity(nftcollectionEntity)
  | TokenEntity(tokenEntity)
  | AEntity(aEntity)
  | BEntity(bEntity)
  | CEntity(cEntity)

type crud = Create | Read | Update | Delete

type eventData = {
  @as("event_chain_id") chainId: int,
  @as("event_id") eventId: string,
}

type inMemoryStoreRow<'a> = {
  crud: crud,
  entity: 'a,
  eventData: eventData,
}

//*************
//**CONTRACTS**
//*************

@genType
type eventLog<'a> = {
  params: 'a,
  blockNumber: int,
  blockTimestamp: int,
  blockHash: string,
  srcAddress: Ethers.ethAddress,
  transactionHash: string,
  transactionIndex: int,
  logIndex: int,
}

module GravatarContract = {
  module TestEventEvent = {
    @spice @genType
    type eventArgs = {
      id: Ethers.BigInt.t,
      user: Ethers.ethAddress,
      contactDetails: (string, string),
    }
    type userEntityHandlerContext = {
      getGravatar: userEntity => option<gravatarEntity>,
      getTokens: userEntity => array<tokenEntity>,
      insert: userEntity => unit,
      update: userEntity => unit,
      delete: id => unit,
    }
    type gravatarEntityHandlerContext = {
      getOwner: gravatarEntity => userEntity,
      insert: gravatarEntity => unit,
      update: gravatarEntity => unit,
      delete: id => unit,
    }
    type nftcollectionEntityHandlerContext = {
      insert: nftcollectionEntity => unit,
      update: nftcollectionEntity => unit,
      delete: id => unit,
    }
    type tokenEntityHandlerContext = {
      getCollection: tokenEntity => nftcollectionEntity,
      getOwner: tokenEntity => userEntity,
      insert: tokenEntity => unit,
      update: tokenEntity => unit,
      delete: id => unit,
    }
    type aEntityHandlerContext = {
      testingA: unit => option<aEntity>,
      getB: aEntity => bEntity,
      insert: aEntity => unit,
      update: aEntity => unit,
      delete: id => unit,
    }
    type bEntityHandlerContext = {
      getA: bEntity => array<aEntity>,
      getC: bEntity => option<cEntity>,
      insert: bEntity => unit,
      update: bEntity => unit,
      delete: id => unit,
    }
    type cEntityHandlerContext = {
      getA: cEntity => aEntity,
      insert: cEntity => unit,
      update: cEntity => unit,
      delete: id => unit,
    }
    @genType
    type context = {
      user: userEntityHandlerContext,
      gravatar: gravatarEntityHandlerContext,
      nftcollection: nftcollectionEntityHandlerContext,
      token: tokenEntityHandlerContext,
      a: aEntityHandlerContext,
      b: bEntityHandlerContext,
      c: cEntityHandlerContext,
    }

    @genType
    type aEntityLoaderContext = {testingALoad: (id, ~loaders: aLoaderConfig=?) => unit}

    @genType
    type contractRegistrations = {
      //TODO only add contracts we've registered for the event in the config
      addGravatar: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addNftFactory: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addSimpleNft: Ethers.ethAddress => unit,
    }
    @genType
    type loaderContext = {
      contractRegistration: contractRegistrations,
      a: aEntityLoaderContext,
    }
  }
  module NewGravatarEvent = {
    @spice @genType
    type eventArgs = {
      id: Ethers.BigInt.t,
      owner: Ethers.ethAddress,
      displayName: string,
      imageUrl: string,
    }
    type userEntityHandlerContext = {
      getGravatar: userEntity => option<gravatarEntity>,
      getTokens: userEntity => array<tokenEntity>,
      insert: userEntity => unit,
      update: userEntity => unit,
      delete: id => unit,
    }
    type gravatarEntityHandlerContext = {
      getOwner: gravatarEntity => userEntity,
      insert: gravatarEntity => unit,
      update: gravatarEntity => unit,
      delete: id => unit,
    }
    type nftcollectionEntityHandlerContext = {
      insert: nftcollectionEntity => unit,
      update: nftcollectionEntity => unit,
      delete: id => unit,
    }
    type tokenEntityHandlerContext = {
      getCollection: tokenEntity => nftcollectionEntity,
      getOwner: tokenEntity => userEntity,
      insert: tokenEntity => unit,
      update: tokenEntity => unit,
      delete: id => unit,
    }
    type aEntityHandlerContext = {
      getB: aEntity => bEntity,
      insert: aEntity => unit,
      update: aEntity => unit,
      delete: id => unit,
    }
    type bEntityHandlerContext = {
      getA: bEntity => array<aEntity>,
      getC: bEntity => option<cEntity>,
      insert: bEntity => unit,
      update: bEntity => unit,
      delete: id => unit,
    }
    type cEntityHandlerContext = {
      getA: cEntity => aEntity,
      insert: cEntity => unit,
      update: cEntity => unit,
      delete: id => unit,
    }
    @genType
    type context = {
      user: userEntityHandlerContext,
      gravatar: gravatarEntityHandlerContext,
      nftcollection: nftcollectionEntityHandlerContext,
      token: tokenEntityHandlerContext,
      a: aEntityHandlerContext,
      b: bEntityHandlerContext,
      c: cEntityHandlerContext,
    }

    @genType
    type contractRegistrations = {
      //TODO only add contracts we've registered for the event in the config
      addGravatar: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addNftFactory: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addSimpleNft: Ethers.ethAddress => unit,
    }
    @genType
    type loaderContext = {contractRegistration: contractRegistrations}
  }
  module UpdatedGravatarEvent = {
    @spice @genType
    type eventArgs = {
      id: Ethers.BigInt.t,
      owner: Ethers.ethAddress,
      displayName: string,
      imageUrl: string,
    }
    type userEntityHandlerContext = {
      getGravatar: userEntity => option<gravatarEntity>,
      getTokens: userEntity => array<tokenEntity>,
      insert: userEntity => unit,
      update: userEntity => unit,
      delete: id => unit,
    }
    type gravatarEntityHandlerContext = {
      gravatarWithChanges: unit => option<gravatarEntity>,
      getOwner: gravatarEntity => userEntity,
      insert: gravatarEntity => unit,
      update: gravatarEntity => unit,
      delete: id => unit,
    }
    type nftcollectionEntityHandlerContext = {
      insert: nftcollectionEntity => unit,
      update: nftcollectionEntity => unit,
      delete: id => unit,
    }
    type tokenEntityHandlerContext = {
      getCollection: tokenEntity => nftcollectionEntity,
      getOwner: tokenEntity => userEntity,
      insert: tokenEntity => unit,
      update: tokenEntity => unit,
      delete: id => unit,
    }
    type aEntityHandlerContext = {
      getB: aEntity => bEntity,
      insert: aEntity => unit,
      update: aEntity => unit,
      delete: id => unit,
    }
    type bEntityHandlerContext = {
      getA: bEntity => array<aEntity>,
      getC: bEntity => option<cEntity>,
      insert: bEntity => unit,
      update: bEntity => unit,
      delete: id => unit,
    }
    type cEntityHandlerContext = {
      getA: cEntity => aEntity,
      insert: cEntity => unit,
      update: cEntity => unit,
      delete: id => unit,
    }
    @genType
    type context = {
      user: userEntityHandlerContext,
      gravatar: gravatarEntityHandlerContext,
      nftcollection: nftcollectionEntityHandlerContext,
      token: tokenEntityHandlerContext,
      a: aEntityHandlerContext,
      b: bEntityHandlerContext,
      c: cEntityHandlerContext,
    }

    @genType
    type gravatarEntityLoaderContext = {
      gravatarWithChangesLoad: (id, ~loaders: gravatarLoaderConfig=?) => unit,
    }

    @genType
    type contractRegistrations = {
      //TODO only add contracts we've registered for the event in the config
      addGravatar: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addNftFactory: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addSimpleNft: Ethers.ethAddress => unit,
    }
    @genType
    type loaderContext = {
      contractRegistration: contractRegistrations,
      gravatar: gravatarEntityLoaderContext,
    }
  }
}
module NftFactoryContract = {
  module SimpleNftCreatedEvent = {
    @spice @genType
    type eventArgs = {
      name: string,
      symbol: string,
      maxSupply: Ethers.BigInt.t,
      contractAddress: Ethers.ethAddress,
    }
    type userEntityHandlerContext = {
      getGravatar: userEntity => option<gravatarEntity>,
      getTokens: userEntity => array<tokenEntity>,
      insert: userEntity => unit,
      update: userEntity => unit,
      delete: id => unit,
    }
    type gravatarEntityHandlerContext = {
      getOwner: gravatarEntity => userEntity,
      insert: gravatarEntity => unit,
      update: gravatarEntity => unit,
      delete: id => unit,
    }
    type nftcollectionEntityHandlerContext = {
      insert: nftcollectionEntity => unit,
      update: nftcollectionEntity => unit,
      delete: id => unit,
    }
    type tokenEntityHandlerContext = {
      getCollection: tokenEntity => nftcollectionEntity,
      getOwner: tokenEntity => userEntity,
      insert: tokenEntity => unit,
      update: tokenEntity => unit,
      delete: id => unit,
    }
    type aEntityHandlerContext = {
      getB: aEntity => bEntity,
      insert: aEntity => unit,
      update: aEntity => unit,
      delete: id => unit,
    }
    type bEntityHandlerContext = {
      getA: bEntity => array<aEntity>,
      getC: bEntity => option<cEntity>,
      insert: bEntity => unit,
      update: bEntity => unit,
      delete: id => unit,
    }
    type cEntityHandlerContext = {
      getA: cEntity => aEntity,
      insert: cEntity => unit,
      update: cEntity => unit,
      delete: id => unit,
    }
    @genType
    type context = {
      user: userEntityHandlerContext,
      gravatar: gravatarEntityHandlerContext,
      nftcollection: nftcollectionEntityHandlerContext,
      token: tokenEntityHandlerContext,
      a: aEntityHandlerContext,
      b: bEntityHandlerContext,
      c: cEntityHandlerContext,
    }

    @genType
    type contractRegistrations = {
      //TODO only add contracts we've registered for the event in the config
      addGravatar: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addNftFactory: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addSimpleNft: Ethers.ethAddress => unit,
    }
    @genType
    type loaderContext = {contractRegistration: contractRegistrations}
  }
}
module SimpleNftContract = {
  module TransferEvent = {
    @spice @genType
    type eventArgs = {
      from: Ethers.ethAddress,
      to: Ethers.ethAddress,
      tokenId: Ethers.BigInt.t,
    }
    type userEntityHandlerContext = {
      userFrom: unit => option<userEntity>,
      userTo: unit => option<userEntity>,
      getGravatar: userEntity => option<gravatarEntity>,
      getTokens: userEntity => array<tokenEntity>,
      insert: userEntity => unit,
      update: userEntity => unit,
      delete: id => unit,
    }
    type gravatarEntityHandlerContext = {
      getOwner: gravatarEntity => userEntity,
      insert: gravatarEntity => unit,
      update: gravatarEntity => unit,
      delete: id => unit,
    }
    type nftcollectionEntityHandlerContext = {
      nftCollectionUpdated: unit => option<nftcollectionEntity>,
      insert: nftcollectionEntity => unit,
      update: nftcollectionEntity => unit,
      delete: id => unit,
    }
    type tokenEntityHandlerContext = {
      existingTransferredToken: unit => option<tokenEntity>,
      getCollection: tokenEntity => nftcollectionEntity,
      getOwner: tokenEntity => userEntity,
      insert: tokenEntity => unit,
      update: tokenEntity => unit,
      delete: id => unit,
    }
    type aEntityHandlerContext = {
      getB: aEntity => bEntity,
      insert: aEntity => unit,
      update: aEntity => unit,
      delete: id => unit,
    }
    type bEntityHandlerContext = {
      getA: bEntity => array<aEntity>,
      getC: bEntity => option<cEntity>,
      insert: bEntity => unit,
      update: bEntity => unit,
      delete: id => unit,
    }
    type cEntityHandlerContext = {
      getA: cEntity => aEntity,
      insert: cEntity => unit,
      update: cEntity => unit,
      delete: id => unit,
    }
    @genType
    type context = {
      user: userEntityHandlerContext,
      gravatar: gravatarEntityHandlerContext,
      nftcollection: nftcollectionEntityHandlerContext,
      token: tokenEntityHandlerContext,
      a: aEntityHandlerContext,
      b: bEntityHandlerContext,
      c: cEntityHandlerContext,
    }

    @genType
    type userEntityLoaderContext = {
      userFromLoad: (id, ~loaders: userLoaderConfig=?) => unit,
      userToLoad: (id, ~loaders: userLoaderConfig=?) => unit,
    }
    @genType
    type nftcollectionEntityLoaderContext = {nftCollectionUpdatedLoad: id => unit}
    @genType
    type tokenEntityLoaderContext = {
      existingTransferredTokenLoad: (id, ~loaders: tokenLoaderConfig=?) => unit,
    }

    @genType
    type contractRegistrations = {
      //TODO only add contracts we've registered for the event in the config
      addGravatar: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addNftFactory: Ethers.ethAddress => unit,
      //TODO only add contracts we've registered for the event in the config
      addSimpleNft: Ethers.ethAddress => unit,
    }
    @genType
    type loaderContext = {
      contractRegistration: contractRegistrations,
      user: userEntityLoaderContext,
      nftcollection: nftcollectionEntityLoaderContext,
      token: tokenEntityLoaderContext,
    }
  }
}

type event =
  | GravatarContract_TestEvent(eventLog<GravatarContract.TestEventEvent.eventArgs>)
  | GravatarContract_NewGravatar(eventLog<GravatarContract.NewGravatarEvent.eventArgs>)
  | GravatarContract_UpdatedGravatar(eventLog<GravatarContract.UpdatedGravatarEvent.eventArgs>)
  | NftFactoryContract_SimpleNftCreated(
      eventLog<NftFactoryContract.SimpleNftCreatedEvent.eventArgs>,
    )
  | SimpleNftContract_Transfer(eventLog<SimpleNftContract.TransferEvent.eventArgs>)

type eventAndContext =
  | GravatarContract_TestEventWithContext(
      eventLog<GravatarContract.TestEventEvent.eventArgs>,
      GravatarContract.TestEventEvent.context,
    )
  | GravatarContract_NewGravatarWithContext(
      eventLog<GravatarContract.NewGravatarEvent.eventArgs>,
      GravatarContract.NewGravatarEvent.context,
    )
  | GravatarContract_UpdatedGravatarWithContext(
      eventLog<GravatarContract.UpdatedGravatarEvent.eventArgs>,
      GravatarContract.UpdatedGravatarEvent.context,
    )
  | NftFactoryContract_SimpleNftCreatedWithContext(
      eventLog<NftFactoryContract.SimpleNftCreatedEvent.eventArgs>,
      NftFactoryContract.SimpleNftCreatedEvent.context,
    )
  | SimpleNftContract_TransferWithContext(
      eventLog<SimpleNftContract.TransferEvent.eventArgs>,
      SimpleNftContract.TransferEvent.context,
    )

@spice
type eventName =
  | @spice.as("GravatarContract_TestEventEvent") GravatarContract_TestEventEvent
  | @spice.as("GravatarContract_NewGravatarEvent") GravatarContract_NewGravatarEvent
  | @spice.as("GravatarContract_UpdatedGravatarEvent") GravatarContract_UpdatedGravatarEvent
  | @spice.as("NftFactoryContract_SimpleNftCreatedEvent") NftFactoryContract_SimpleNftCreatedEvent
  | @spice.as("SimpleNftContract_TransferEvent") SimpleNftContract_TransferEvent

let eventNameToString = (eventName: eventName) =>
  switch eventName {
  | GravatarContract_TestEventEvent => "TestEvent"
  | GravatarContract_NewGravatarEvent => "NewGravatar"
  | GravatarContract_UpdatedGravatarEvent => "UpdatedGravatar"
  | NftFactoryContract_SimpleNftCreatedEvent => "SimpleNftCreated"
  | SimpleNftContract_TransferEvent => "Transfer"
  }
