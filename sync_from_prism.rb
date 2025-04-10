require "Pathname"

# This script assumes you have this layout:
# ├── Ruby
# │   └── prism
# └── Shopify
#     └── rbs <---- current working directory

import_from_prism("../../ruby/prism/include/prism/defines.h")
import_from_prism("../../ruby/prism/include/prism/util/pm_constant_pool.h")
import_from_prism("../../ruby/prism/src/util/pm_constant_pool.c")

BEGIN {
  def import_from_prism(prism_file_path_str)
    prism_file_path = Pathname.new(prism_file_path_str).realpath
    puts prism_file_path

    dest_file_path_str = "./" + prism_file_path_str.delete_prefix("../../ruby/prism/")
    dest_file_path_str.gsub!("include/prism/", "include/rbs/")
    dest_file_path_str.gsub!("pm_", "rbs_")

    dest_file_path = Pathname.new(dest_file_path_str).expand_path
    puts dest_file_path.dirname.mkpath

    puts "Importing \"#{prism_file_path.relative_path_from(Pathname.pwd)}\" to \"#{dest_file_path.relative_path_from(Pathname.pwd)}\""

    contents = File.read(prism_file_path)

    contents.gsub!("PRISM", "RBS")
    contents.gsub!("Prism", "RBS")
    contents.gsub!("prism", "rbs")
    contents.gsub!("pm_", "rbs_")
    contents.gsub!("PM_", "RBS_")

    File.write(dest_file_path, contents)
  end
}
