# Because refinements are scoped per-file, we have to make a separate file to
# query refinements, so they don't mess up the rest of the `Module_test`.
module ModuleTestHelperRefinement
  refine Class.new do
    def blah = 34
  end
end

using ModuleTestHelperRefinement

ModuleTestHelperRefinement::USED_MODULES = Module.used_modules
ModuleTestHelperRefinement::USED_REFINEMENTS = Module.used_refinements
