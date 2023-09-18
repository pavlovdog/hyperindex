use std::error::Error;

use std::path::PathBuf;

use crate::cli_args::{
    interactive_init::TemplateOrSubgraphID, InitArgs, InitNextArgs, Language, Template,
    ToProjectPathsArgs,
};
use crate::commands;
use crate::config_parsing::contract_migration::generate_config_from_contract_address;
use crate::config_parsing::graph_migration::generate_config_from_subgraph_id;
use crate::hbs_templating::{
    hbs_dir_generator::HandleBarsDirGenerator, init_templates::InitTemplates,
};
use crate::project_paths::ParsedPaths;

use include_dir::{include_dir, Dir};

static BLANK_TEMPLATE_STATIC_SHARED_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/blank_template/shared");
static BLANK_TEMPLATE_STATIC_RESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/blank_template/rescript");
static BLANK_TEMPLATE_STATIC_TYPESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/blank_template/typescript");
static BLANK_TEMPLATE_STATIC_JAVASCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/blank_template/javascript");
static BLANK_TEMPLATE_DYNAMIC_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/dynamic/blank_template");
static GREETER_TEMPLATE_STATIC_SHARED_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/greeter_template/shared");
static GREETER_TEMPLATE_STATIC_RESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/greeter_template/rescript");
static GREETER_TEMPLATE_STATIC_TYPESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/greeter_template/typescript");
static GREETER_TEMPLATE_STATIC_JAVASCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/greeter_template/javascript");
static ERC20_TEMPLATE_STATIC_SHARED_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/erc20_template/shared");
static ERC20_TEMPLATE_STATIC_RESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/erc20_template/rescript");
static ERC20_TEMPLATE_STATIC_TYPESCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/erc20_template/typescript");
static ERC20_TEMPLATE_STATIC_JAVASCRIPT_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/static/erc20_template/javascript");
static INIT_TEMPLATES_SHARED_DIR: Dir<'_> =
    include_dir!("$CARGO_MANIFEST_DIR/templates/dynamic/init_templates/shared");

pub async fn run_init_args(init_args: &InitArgs) -> Result<(), Box<dyn Error>> {
    //get_init_args_interactive opens an interactive cli for required args to be selected
    //if they haven't already been
    let parsed_init_args = init_args.get_init_args_interactive()?;
    let project_root_path = PathBuf::from(&parsed_init_args.directory);
    // The cli errors if the folder exists, the user must provide a new folder to proceed which we create below
    std::fs::create_dir_all(&project_root_path)?;

    let hbs_template =
        InitTemplates::new(parsed_init_args.name.clone(), &parsed_init_args.language);

    let hbs_generator = HandleBarsDirGenerator::new(
        &INIT_TEMPLATES_SHARED_DIR,
        &hbs_template,
        &project_root_path,
    );

    match &parsed_init_args.template {
        TemplateOrSubgraphID::Template(template) => match template {
            Template::Blank => {
                //Copy in the relevant language specific blank template files
                match &parsed_init_args.language {
                    Language::Rescript => {
                        BLANK_TEMPLATE_STATIC_RESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Typescript => {
                        BLANK_TEMPLATE_STATIC_TYPESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Javascript => {
                        BLANK_TEMPLATE_STATIC_JAVASCRIPT_DIR.extract(&project_root_path)?;
                    }
                }
                //Copy in the rest of the shared blank template files
                BLANK_TEMPLATE_STATIC_SHARED_DIR.extract(&project_root_path)?;

                let hbs_config_file = HandleBarsDirGenerator::new(
                    &BLANK_TEMPLATE_DYNAMIC_DIR,
                    &hbs_template,
                    &project_root_path,
                );

                hbs_config_file.generate_hbs_templates()?;
            }
            Template::Greeter => {
                //Copy in the relevant language specific greeter files
                match &parsed_init_args.language {
                    Language::Rescript => {
                        GREETER_TEMPLATE_STATIC_RESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Typescript => {
                        GREETER_TEMPLATE_STATIC_TYPESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Javascript => {
                        GREETER_TEMPLATE_STATIC_JAVASCRIPT_DIR.extract(&project_root_path)?;
                    }
                }
                //Copy in the rest of the shared greeter files
                GREETER_TEMPLATE_STATIC_SHARED_DIR.extract(&project_root_path)?;
            }
            Template::Erc20 => {
                //Copy in the relevant js flavor specific greeter files
                match &parsed_init_args.language {
                    Language::Rescript => {
                        ERC20_TEMPLATE_STATIC_RESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Typescript => {
                        ERC20_TEMPLATE_STATIC_TYPESCRIPT_DIR.extract(&project_root_path)?;
                    }
                    Language::Javascript => {
                        ERC20_TEMPLATE_STATIC_JAVASCRIPT_DIR.extract(&project_root_path)?;
                    }
                }
                //Copy in the rest of the shared greeter files
                ERC20_TEMPLATE_STATIC_SHARED_DIR.extract(&project_root_path)?;
            }
        },
        TemplateOrSubgraphID::SubgraphID(cid) => {
            //  Copy in the relevant js flavor specific subgraph migration files
            match &parsed_init_args.language {
                Language::Rescript => {
                    BLANK_TEMPLATE_STATIC_RESCRIPT_DIR.extract(&project_root_path)?;
                }
                Language::Typescript => {
                    BLANK_TEMPLATE_STATIC_TYPESCRIPT_DIR.extract(&project_root_path)?;
                }
                Language::Javascript => {
                    BLANK_TEMPLATE_STATIC_JAVASCRIPT_DIR.extract(&project_root_path)?;
                }
            }
            //Copy in the rest of the shared subgraph migration files
            BLANK_TEMPLATE_STATIC_SHARED_DIR.extract(&project_root_path)?;

            generate_config_from_subgraph_id(&project_root_path, cid, &parsed_init_args.language)
                .await?;
        }
    }

    hbs_generator.generate_hbs_templates()?;

    println!("Project template ready");
    println!("Running codegen");

    let parsed_paths = ParsedPaths::new(parsed_init_args.to_project_paths_args())?;
    let project_paths = &parsed_paths.project_paths;
    commands::codegen::run_codegen(&parsed_paths).await?;

    let post_codegen_exit =
        commands::codegen::run_post_codegen_command_sequence(project_paths).await?;

    if !post_codegen_exit.success() {
        return Err("Failed to complete post codegen command sequence")?;
    }

    if parsed_init_args.language == Language::Rescript {
        let res_build_exit = commands::rescript::build(&project_paths.project_root).await?;
        if !res_build_exit.success() {
            return Err("Failed to build rescript")?;
        }
    }

    // If the project directory is not the current directory, print a message for user to cd into it
    if project_paths.project_root != PathBuf::from(".") {
        println!(
            "Please run `cd {}` to run the rest of the envio commands",
            project_paths.project_root.to_str().unwrap_or("")
        );
    }

    Ok(())
}

pub async fn run_init_next_args(init_next_args: &InitNextArgs) -> Result<(), Box<dyn Error>> {
    //get_init_args_interactive opens an interactive cli for required args to be selected
    //if they haven't already been
    let parsed_init_next_args = init_next_args.get_init_args_interactive()?;
    let project_root_path = PathBuf::from(&parsed_init_next_args.directory);
    // The cli errors if the folder exists, the user must provide a new folder to proceed which we create below
    std::fs::create_dir_all(&project_root_path)?;

    let hbs_template = InitTemplates::new(
        parsed_init_next_args.name.clone(),
        &parsed_init_next_args.language,
    );

    let hbs_generator = HandleBarsDirGenerator::new(
        &INIT_TEMPLATES_SHARED_DIR,
        &hbs_template,
        &project_root_path,
    );

    //  Copy in the relevant js flavor specific subgraph migration files
    match &parsed_init_next_args.language {
        Language::Rescript => {
            BLANK_TEMPLATE_STATIC_RESCRIPT_DIR.extract(&project_root_path)?;
        }
        Language::Typescript => {
            BLANK_TEMPLATE_STATIC_TYPESCRIPT_DIR.extract(&project_root_path)?;
        }
        Language::Javascript => {
            BLANK_TEMPLATE_STATIC_JAVASCRIPT_DIR.extract(&project_root_path)?;
        }
    }
    //Copy in the rest of the shared subgraph migration files
    BLANK_TEMPLATE_STATIC_SHARED_DIR.extract(&project_root_path)?;

    generate_config_from_contract_address(
        &parsed_init_next_args.name,
        &project_root_path,
        &parsed_init_next_args.contract_address,
        &parsed_init_next_args.language,
    )
    .await?;

    hbs_generator.generate_hbs_templates()?;

    println!("Project template ready");
    println!("Running codegen");

    let parsed_paths = ParsedPaths::new(parsed_init_next_args.to_project_paths_args())?;
    let project_paths = &parsed_paths.project_paths;
    commands::codegen::run_codegen(&parsed_paths).await?;

    let post_codegen_exit =
        commands::codegen::run_post_codegen_command_sequence(project_paths).await?;

    if !post_codegen_exit.success() {
        return Err("Failed to complete post codegen command sequence")?;
    }

    if parsed_init_next_args.language == Language::Rescript {
        let res_build_exit = commands::rescript::build(&project_paths.project_root).await?;
        if !res_build_exit.success() {
            return Err("Failed to build rescript")?;
        }
    }
    Ok(())
}
