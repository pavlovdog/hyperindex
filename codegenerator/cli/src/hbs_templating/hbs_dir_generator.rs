use std::fs;
use std::path::Path;

use handlebars::Handlebars;

use include_dir::{Dir, DirEntry};
use serde::Serialize;

use crate::project_paths::path_utils::normalize_path;

pub struct HandleBarsDirGenerator<'a, T: Serialize> {
    handlebars: handlebars::Handlebars<'a>,
    templates_dir: &'a Dir<'a>,
    rs_template: &'a T,
    output_dir: &'a Path,
}

impl<'a, T: Serialize> HandleBarsDirGenerator<'a, T> {
    pub fn new(templates_dir: &'a Dir, rs_template: &'a T, output_dir: &'a Path) -> Self {
        let mut handlebars = Handlebars::new();
        handlebars.set_strict_mode(true);
        handlebars.register_escape_fn(handlebars::no_escape);

        HandleBarsDirGenerator {
            handlebars,
            templates_dir,
            rs_template,
            output_dir,
        }
    }

    fn generate_hbs_templates_internal_recursive(
        &self,
        hbs_templates_root_dir: &Dir,
    ) -> Result<(), String> {
        for entry in hbs_templates_root_dir.entries() {
            match entry {
                DirEntry::File(file) => {
                    let path = file.path();
                    let is_hbs_file = path.extension().map_or(false, |ext| ext == "hbs");

                    if is_hbs_file {
                        // let get_path_str = |path: AsRef<Path>>| path.to_str().unwrap_or_else(|| "bad path");
                        let path_str = path
                            .to_str()
                            .ok_or("Could not cast path to str in generate_hbs_templates")?;
                        //Get the parent of the file src/MyTemplate.res.hbs -> src/
                        let parent = path
                            .parent()
                            .ok_or_else(|| format!("Could not produce parent of {}", path_str))?;

                        //Get the file stem src/MyTemplate.res.hbs -> MyTemplate.res
                        let file_stem = path
                            .file_stem()
                            .ok_or_else(|| format!("Could not produce filestem of {}", path_str))?;

                        //Read the template file contents
                        let file_str = file.contents_utf8().ok_or_else(|| {
                            format!("Could not produce file contents of {}", path_str)
                        })?;

                        //Render the template
                        let rendered_file = self
                            .handlebars
                            .render_template(file_str, &self.rs_template)
                            .map_err(|e| {
                                format!("Could not render file at {} error: {}", path_str, e)
                            })?;

                        //Setup output directory
                        let output_dir_path =
                            normalize_path(self.output_dir.join(parent).as_path());
                        let output_dir_path_str = output_dir_path.to_str().ok_or({
                            "Could not cast output path to str in generate_hbs_templates"
                        })?;

                        //ensure the dir exists or is created
                        fs::create_dir_all(&output_dir_path).map_err(|e| {
                            format!(
                                "create_dir_all failed at {} error: {}",
                                &output_dir_path_str, e
                            )
                        })?;

                        //append the filename
                        let output_file_path = output_dir_path.join(file_stem);

                        //Write the file
                        fs::write(&output_file_path, rendered_file).map_err(|e| {
                            format!("file write failed at {} error: {}", &output_dir_path_str, e)
                        })?;
                    }
                }
                DirEntry::Dir(dir) => Self::generate_hbs_templates_internal_recursive(self, dir)?,
            }
        }
        Ok(())
    }
    pub fn generate_hbs_templates(&self) -> Result<(), String> {
        Self::generate_hbs_templates_internal_recursive(self, self.templates_dir)
    }
}
