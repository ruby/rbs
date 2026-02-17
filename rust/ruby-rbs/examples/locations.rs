use ruby_rbs::node::{Node, parse};

fn main() {
    let rbs_code = r#"class Foo[T] < Bar end"#;
    let signature = parse(rbs_code.as_bytes()).unwrap();

    let declaration = signature.declarations().iter().next().unwrap();
    if let Node::Class(class) = declaration {
        println!("Class declaration: '{}'", rbs_code);
        println!(
            "Overall location: {}..{}",
            class.location().start(),
            class.location().end()
        );

        // Required sub-locations
        let keyword = class.keyword_location();
        println!(
            "  keyword location: {}..{} = '{}'",
            keyword.start(),
            keyword.end(),
            &rbs_code[keyword.start() as usize..keyword.end() as usize]
        );

        let name = class.name_location();
        println!(
            "  name location: {}..{} = '{}'",
            name.start(),
            name.end(),
            &rbs_code[name.start() as usize..name.end() as usize]
        );

        let end_loc = class.end_location();
        println!(
            "  end location: {}..{} = '{}'",
            end_loc.start(),
            end_loc.end(),
            &rbs_code[end_loc.start() as usize..end_loc.end() as usize]
        );

        // Optional sub-locations
        if let Some(type_params) = class.type_params_location() {
            println!(
                "  type_params location: {}..{} = '{}'",
                type_params.start(),
                type_params.end(),
                &rbs_code[type_params.start() as usize..type_params.end() as usize]
            );
        }

        if let Some(lt) = class.lt_location() {
            println!(
                "  lt location: {}..{} = '{}'",
                lt.start(),
                lt.end(),
                &rbs_code[lt.start() as usize..lt.end() as usize]
            );
        }
    }
}
