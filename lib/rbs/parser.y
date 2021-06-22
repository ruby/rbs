class RBS::Parser
  token tUIDENT tLIDENT tUNDERSCOREIDENT tNAMESPACE tINTERFACEIDENT tGLOBALIDENT
        tLKEYWORD tUKEYWORD tLKEYWORD_Q_E tUKEYWORD_Q_E
        tIVAR tCLASSVAR
        tANNOTATION
        tSTRING tSYMBOL tINTEGER tWRITE_ATTR
        kLPAREN kRPAREN kLBRACKET kRBRACKET kLBRACE kRBRACE
        kVOID kNIL kTRUE kFALSE kANY kUNTYPED kTOP kBOT kSELF kSELFQ kINSTANCE kCLASS kBOOL kSINGLETON kTYPE kDEF kMODULE
        kPRIVATE kPUBLIC kALIAS
        kCOLON kCOLON2 kCOMMA kBAR kAMP kHAT kARROW kQUESTION kEXCLAMATION kSTAR kSTAR2 kFATARROW kEQ kDOT kDOT3 kLT
        kINTERFACE kEND kINCLUDE kEXTEND kATTRREADER kATTRWRITER kATTRACCESSOR tOPERATOR tQUOTEDMETHOD tQUOTEDIDENT
        kPREPEND kEXTENSION kINCOMPATIBLE
        type_TYPE type_SIGNATURE type_METHODTYPE tEOF
        kOUT kIN kUNCHECKED kOVERLOAD

  prechigh
  nonassoc kQUESTION
  left kAMP
  left kBAR
  nonassoc kARROW
  preclow

  expect 5

rule

  target:
      type_TYPE type eof {
        result = val[1]
      }
    | type_SIGNATURE signatures eof {
        result = val[1]
      }
    | type_METHODTYPE method_type eof {
        result = val[1]
      }

  eof: | tEOF

  signatures:
      { result = [] }
    | signatures signature {
        result = val[0].push(val[1])
      }

  signature:
      type_decl
    | const_decl
    | global_decl
    | interface_decl
    | module_decl
    | class_decl

  start_new_scope: { start_new_variables_scope }
  start_merged_scope: { start_merged_variables_scope }

  annotations:
      { result = [] }
    | tANNOTATION annotations {
        result = val[1].unshift(Annotation.new(string: val[0].value, location: val[0].location))
      }

  class_decl:
      annotations kCLASS start_new_scope class_name module_type_params super_class class_members kEND {
        reset_variable_scope

        location = val[1].location + val[7].location
        location = location.with_children(
          required: {
            keyword: val[1].location,
            name: val[3].location,
            end: val[7].location
          },
          optional: {
            type_params: val[4]&.location,
            lt: val[5]&.location
          }
        )
        result = Declarations::Class.new(
          name: val[3].value,
          type_params: val[4]&.value || Declarations::ModuleTypeParams.empty,
          super_class: val[5]&.value,
          members: val[6],
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }

  super_class:
      { result = nil }
    | kLT class_name {
        loc = val[1].location.with_children(
          required: { name: val[1].location },
          optional: { args: nil }
        )
        sup = Declarations::Class::Super.new(name: val[1].value, args: [], location: loc)
        result = LocatedValue.new(value: sup, location: val[0].location)
      }
    | kLT class_name kLBRACKET type_list kRBRACKET {
        loc = (val[1].location + val[4].location).with_children(
          required: { name: val[1].location },
          optional: { args: val[2].location + val[4].location }
        )
        sup = Declarations::Class::Super.new(name: val[1].value, args: val[3], location: loc)
        result = LocatedValue.new(value: sup, location: val[0].location)
      }

  module_decl:
      annotations kMODULE start_new_scope class_name module_type_params colon_module_self_types class_members kEND {
        reset_variable_scope

        colon_loc = val[5].location
        self_loc = val[5].value.yield_self do |params|
          case params.size
          when 0
            nil
          when 1
            params[0].location
          else
            params.first.location + params.last.location
          end
        end

        location = val[1].location + val[7].location
        location = location.with_children(
          required: {
            keyword: val[1].location,
            name: val[3].location,
            end: val[7].location
          },
          optional: {
            type_params: val[4]&.location,
            colon: colon_loc,
            self_types: self_loc
          }
        )
        result = Declarations::Module.new(
          name: val[3].value,
          type_params: val[4]&.value || Declarations::ModuleTypeParams.empty,
          self_types: val[5].value,
          members: val[6],
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }
    | annotations kMODULE start_new_scope namespace tUKEYWORD module_self_types class_members kEND {
        reset_variable_scope

        location = val[1].location + val[7].location
        name_loc, colon_loc = split_kw_loc(val[4].location)
        self_loc = case val[5].size
                   when 0
                     nil
                   when 1
                     val[5][0].location
                   else
                     val[5].first.location + val[5].last.location
                   end
        location = location.with_children(
          required: { keyword: val[1].location, name: name_loc, end: val[7].location },
          optional: { colon: colon_loc, type_params: nil, self_types: self_loc }
        )

        result = Declarations::Module.new(
          name: RBS::TypeName.new(name: val[4].value, namespace: val[3]&.value || RBS::Namespace.empty),
          type_params: Declarations::ModuleTypeParams.empty,
          self_types: val[5],
          members: val[6],
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }

  colon_module_self_types:
      { result = LocatedValue.new(value: [], location: nil) }
    | kCOLON module_self_types {
        result = LocatedValue.new(value: val[1], location: val[0].location)
      }

  module_self_types:
      module_self_type {
        result = [val[0]]
      }
    | module_self_types kCOMMA module_self_type {
        result = val[0].push(val[2])
      }

  module_self_type:
      qualified_name kLBRACKET type_list kRBRACKET {
        name = val[0].value
        args = val[2]
        location = val[0].location + val[3].location
        location = location.with_children(
          required: { name: val[0].location },
          optional: { args: val[1].location + val[3].location }
        )

        case
        when name.class?
          result = Declarations::Module::Self.new(name: name, args: args, location: location)
        when name.interface?
          result = Declarations::Module::Self.new(name: name, args: args, location: location)
        else
          raise SemanticsError.new("Module self type should be instance or interface", subject: val[0], location: val[0].location)
        end
      }
    | qualified_name {
        name = val[0].value
        args = []
        location = val[0].location.with_children(
          required: { name: val[0].location },
          optional: { args: nil }
        )

        case
        when name.class?
          result = Declarations::Module::Self.new(name: name, args: args, location: location)
        when name.interface?
          result = Declarations::Module::Self.new(name: name, args: args, location: location)
        else
          raise SemanticsError.new("Module self type should be instance or interface", subject: val[0], location: val[0].location)
        end
      }

  class_members:
      { result = [] }
    | class_members class_member {
        result = val[0].push(val[1])
      }

  class_member:
      method_member
    | include_member
    | extend_member
    | prepend_member
    | var_type_member
    | attribute_member
    | kPUBLIC {
        result = Members::Public.new(location: val[0].location)
      }
    | kPRIVATE {
        result = Members::Private.new(location: val[0].location)
      }
    | alias_member
    | signature

  attribute_kind:
      { result = LocatedValue.new(value: :instance, location: nil) }
    | kSELF kDOT { result = LocatedValue.new(value: :singleton, location: val[0].location + val[1].location) }

  attribute_member:
      annotations kATTRREADER attribute_kind keyword type {
        location = val[1].location + val[4].location
        name_loc, colon_loc = split_kw_loc(val[3].location)
        location = location.with_children(
          required: { keyword: val[1].location, name: name_loc, colon: colon_loc },
          optional: { ivar: nil, ivar_name: nil, kind: val[2].location }
        )
        result = Members::AttrReader.new(name: val[3].value,
                                         ivar_name: nil,
                                         type: val[4],
                                         kind: val[2].value,
                                         annotations: val[0],
                                         location: location,
                                         comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kATTRREADER attribute_kind method_name attr_var_opt kCOLON type {
        location = val[1].location + val[6].location
        ivar_loc = val[4]&.location
        case name_value = val[4]&.value
        when LocatedValue
          ivar_name = name_value.value
          ivar_name_loc = name_value.location
        when false
          ivar_name = false
          ivar_name_loc = nil
        else
          ivar_name = nil
          ivar_loc = nil
        end
        location = location.with_children(
          required: { keyword: val[1].location, name: val[3].location, colon: val[5].location },
          optional: { ivar: ivar_loc, ivar_name: ivar_name_loc, kind: val[2].location }
        )
        result = Members::AttrReader.new(name: val[3].value.to_sym,
                                         ivar_name: ivar_name,
                                         type: val[6],
                                         kind: val[2].value,
                                         annotations: val[0],
                                         location: location,
                                         comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kATTRWRITER attribute_kind keyword type {
        location = val[1].location + val[4].location
        name_loc, colon_loc = split_kw_loc(val[3].location)
        location = location.with_children(
          required: { keyword: val[1].location, name: name_loc, colon: colon_loc },
          optional: { ivar: nil, ivar_name: nil, kind: val[2].location }
        )
        result = Members::AttrWriter.new(name: val[3].value,
                                         ivar_name: nil,
                                         kind: val[2].value,
                                         type: val[4],
                                         annotations: val[0],
                                         location: location,
                                         comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kATTRWRITER attribute_kind method_name attr_var_opt kCOLON type {
        location = val[1].location + val[6].location
        ivar_loc = val[4]&.location
        case name_value = val[4]&.value
        when LocatedValue
          ivar_name = name_value.value
          ivar_name_loc = name_value.location
        when false
          ivar_name = false
          ivar_name_loc = nil
        else
          ivar_name = nil
          ivar_loc = nil
        end
        location = location.with_children(
          required: { keyword: val[1].location, name: val[3].location, colon: val[5].location },
          optional: { ivar: ivar_loc, ivar_name: ivar_name_loc, kind: val[2].location }
        )

        result = Members::AttrWriter.new(name: val[3].value.to_sym,
                                         ivar_name: ivar_name,
                                         kind: val[2].value,
                                         type: val[6],
                                         annotations: val[0],
                                         location: location,
                                         comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kATTRACCESSOR attribute_kind keyword type {
        location = val[1].location + val[4].location
        name_loc, colon_loc = split_kw_loc(val[3].location)
        location = location.with_children(
          required: { keyword: val[1].location, name: name_loc, colon: colon_loc },
          optional: { ivar: nil, ivar_name: nil, kind: val[2].location }
        )

        result = Members::AttrAccessor.new(name: val[3].value,
                                           ivar_name: nil,
                                           kind: val[2].value,
                                           type: val[4],
                                           annotations: val[0],
                                           location: location,
                                           comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kATTRACCESSOR attribute_kind method_name attr_var_opt kCOLON type {
        location = val[1].location + val[6].location
        ivar_loc = val[4]&.location
        case name_value = val[4]&.value
        when LocatedValue
          ivar_name = name_value.value
          ivar_name_loc = name_value.location
        when false
          ivar_name = false
          ivar_name_loc = nil
        else
          ivar_name = nil
          ivar_loc = nil
        end
        location = location.with_children(
          required: { keyword: val[1].location, name: val[3].location, colon: val[5].location },
          optional: { ivar: ivar_loc, ivar_name: ivar_name_loc, kind: val[2].location }
        )

        result = Members::AttrAccessor.new(name: val[3].value.to_sym,
                                           ivar_name: ivar_name,
                                           kind: val[2].value,
                                           type: val[6],
                                           annotations: val[0],
                                           location: location,
                                           comment: leading_comment(val[0].first&.location || location))
      }

  attr_var_opt:
      { result = nil }
    | kLPAREN kRPAREN { result = LocatedValue.new(value: false, location: val[0].location + val[1].location) }
    | kLPAREN tIVAR kRPAREN {
        result = LocatedValue.new(
          value: val[1],
          location: val[0].location + val[2].location
        )
      }

  var_type_member:
      tIVAR kCOLON type {
        location = (val[0].location + val[2].location).with_children(
          required: { name: val[0].location, colon: val[1].location },
          optional: { kind: nil }
        )

        result = Members::InstanceVariable.new(
          name: val[0].value,
          type: val[2],
          location: location,
          comment: leading_comment(location)
        )
      }
    | tCLASSVAR kCOLON type {
        type = val[2]

        if type.is_a?(Types::Variable)
          type = Types::ClassInstance.new(
            name: TypeName.new(name: type.name, namespace: Namespace.empty),
            args: [],
            location: type.location
          )
        end

        location = (val[0].location + val[2].location).with_children(
          required: { name: val[0].location, colon: val[1].location },
          optional: { kind: nil }
        )

        result = Members::ClassVariable.new(
          name: val[0].value,
          type: type,
          location: location,
          comment: leading_comment(location)
        )
      }
    | kSELF kDOT tIVAR kCOLON type {
      type = val[4]

      if type.is_a?(Types::Variable)
        type = Types::ClassInstance.new(
          name: TypeName.new(name: type.name, namespace: Namespace.empty),
          args: [],
          location: type.location
        )
      end

      location = (val[0].location + val[4].location).with_children(
        required: { name: val[2].location, colon: val[3].location },
        optional: { kind: val[0].location + val[1].location }
      )

      result = Members::ClassInstanceVariable.new(
        name: val[2].value,
        type: type,
        location: location,
        comment: leading_comment(location)
      )
    }

  interface_decl:
      annotations kINTERFACE start_new_scope interface_name module_type_params interface_members kEND {
        reset_variable_scope

        location = val[1].location + val[6].location
        location = location.with_children(
          required: { keyword: val[1].location, name: val[3].location, end: val[6].location },
          optional: { type_params: val[4]&.location }
        )
        result = Declarations::Interface.new(
          name: val[3].value,
          type_params: val[4]&.value || Declarations::ModuleTypeParams.empty,
          members: val[5],
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }

  interface_members:
      { result = [] }
    | interface_members interface_member {
        result = val[0].push(val[1])
      }

  interface_member:
      method_member {
        unless val[0].kind == :instance
          raise SemanticsError.new("Interface cannot have singleton method", subject: val[0], location: val[0].location)
        end

        if val[0].types.last == :super
          raise SemanticsError.new("Interface method cannot have `super` type", subject: val[0], location: val[0].location)
        end

        result = val[0]
      }
    | include_member {
        unless val[0].name.interface?
          raise SemanticsError.new("Interface should include an interface", subject: val[0], location: val[0].location)
        end

        result = val[0]
      }
    | alias_member

  include_member:
      annotations kINCLUDE qualified_name {
        if val[2].value.alias?
          raise SemanticsError.new("Should include module or interface", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[2].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: nil }
        )

        result = Members::Include.new(name: val[2].value,
                                      args: [],
                                      annotations: val[0],
                                      location: location,
                                      comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kINCLUDE qualified_name kLBRACKET type_list kRBRACKET {
        if val[2].value.alias?
          raise SemanticsError.new("Should include module or interface", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[5].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: val[3].location + val[5].location }
        )

        result = Members::Include.new(name: val[2].value,
                                      args: val[4],
                                      annotations: val[0],
                                      location: location,
                                      comment: leading_comment(val[0].first&.location || location))
      }

  extend_member:
      annotations kEXTEND qualified_name {
        if val[2].value.alias?
          raise SemanticsError.new("Should extend module or interface", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[2].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: nil }
        )

        result = Members::Extend.new(name: val[2].value,
                                     args: [],
                                     annotations: val[0],
                                     location: location,
                                     comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kEXTEND qualified_name kLBRACKET type_list kRBRACKET {
        if val[2].value.alias?
          raise SemanticsError.new("Should extend module or interface", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[5].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: val[3].location + val[5].location }
        )

        result = Members::Extend.new(name: val[2].value,
                                     args: val[4],
                                     annotations: val[0],
                                     location: location,
                                     comment: leading_comment(val[0].first&.location || location))
    }

  prepend_member:
      annotations kPREPEND qualified_name {
        unless val[2].value.class?
          raise SemanticsError.new("Should prepend module", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[2].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: nil }
        )

        result = Members::Prepend.new(name: val[2].value,
                                      args: [],
                                      annotations: val[0],
                                      location: location,
                                      comment: leading_comment(val[0].first&.location || location))
      }
    | annotations kPREPEND qualified_name kLBRACKET type_list kRBRACKET {
        unless val[2].value.class?
          raise SemanticsError.new("Should prepend module", subject: val[2].value, location: val[2].location)
        end

        location = (val[1].location + val[5].location).with_children(
          required: { keyword: val[1].location, name: val[2].location },
          optional: { args: val[3].location + val[5].location }
        )

        result = Members::Prepend.new(name: val[2].value,
                                      args: val[4],
                                      annotations: val[0],
                                      location: location,
                                      comment: leading_comment(val[0].first&.location || location))
      }

  overload:
        { result = nil }
    | kOVERLOAD {
        RBS.logger.warn "`overload def` syntax is deprecated. Use `...` syntax instead."
        result = val[0]
      }

  method_member:
      annotations attributes overload kDEF method_kind def_name method_types {
        location = val[3].location + val[6].last.location

        required_children = { keyword: val[3].location, name: val[5].location }
        optional_children = { kind: nil, overload: nil }

        if val[4]
          kind = val[4].value
          optional_children[:kind] = val[4].location
        else
          kind = :instance
        end

        last_type = val[6].last
        if last_type.is_a?(LocatedValue) && last_type.value == :dot3
          overload = true
          optional_children[:overload] = last_type.location
          val[6].pop
        else
          overload = false
        end

        result = Members::MethodDefinition.new(
          name: val[5].value,
          kind: kind,
          types: val[6],
          annotations: val[0],
          location: location.with_children(required: required_children, optional: optional_children),
          comment: leading_comment(val[0].first&.location || val[2]&.location || val[3].location),
          overload: overload || !!val[2]
        )
      }

  attributes:
    | attributes kINCOMPATIBLE {
        RBS.logger.warn "`incompatible` method attribute is deprecated and ignored."
      }

  method_kind:
      { result = nil }
    | kSELF kDOT { result = LocatedValue.new(value: :singleton, location: val[0].location + val[1].location) }
    | kSELFQ kDOT { result = LocatedValue.new(value: :singleton_instance, location: val[0].location + val[1].location) }

  method_types:
      method_type { result = [val[0]] }
    | kDOT3 { result = [LocatedValue.new(value: :dot3, location: val[0].location)] }
    | method_type kBAR method_types {
        result = val[2].unshift(val[0])
      }

  method_type:
      start_merged_scope type_params proc_type {
        reset_variable_scope

        location = (val[1] || val[2]).location + val[2].location
        type_params = val[1]&.value || []

        type, block = val[2].value

        result = MethodType.new(type_params: type_params,
                                type: type,
                                block: block,
                                location: location)
      }

  params_opt:
      { result = nil }
    | kLPAREN params kRPAREN {
        result = LocatedValue.new(value: val[1], location: val[0].location + val[2].location)
      }

  block:
      kLBRACE simple_function_type kRBRACE {
        block = Types::Block.new(type: val[1].value, required: true)
        result = LocatedValue.new(value: block, location: val[0].location + val[2].location)
      }
    | kQUESTION kLBRACE simple_function_type kRBRACE {
        block = Types::Block.new(type: val[2].value, required: false)
        result = LocatedValue.new(value: block, location: val[0].location + val[3].location)
      }

  def_name:
      keyword {
        loc = val[0].location

        result = LocatedValue.new(
          value: val[0].value,
          location: Location.new(buffer: loc.buffer, start_pos: loc.start_pos, end_pos: loc.end_pos - 1)
        )
      }
    | method_name kCOLON {
        result = LocatedValue.new(value: val[0].value.to_sym,
                                  location: val[0].location + val[1].location)
      }

  method_name:
      tOPERATOR
    | kAMP | kHAT | kSTAR | kLT | kEXCLAMATION | kSTAR2 | kBAR
    | method_name0
    | method_name0 kQUESTION {
        unless val[0].location.pred?(val[1].location)
          raise SyntaxError.new(token_str: "kQUESTION", error_value: val[1])
        end

        result = LocatedValue.new(value: "#{val[0].value}?",
                                  location: val[0].location + val[1].location)
      }
    | method_name0 kEXCLAMATION {
        unless val[0].location.pred?(val[1].location)
          raise SyntaxError.new(token_str: "kEXCLAMATION", error_value: val[1])
        end

        result = LocatedValue.new(value: "#{val[0].value}!",
                                  location: val[0].location + val[1].location)
      }
    | tQUOTEDMETHOD
    | tQUOTEDIDENT
    | tWRITE_ATTR

  method_name0: tUIDENT | tLIDENT | tINTERFACEIDENT | identifier_keywords

  identifier_keywords:
      kCLASS | kVOID | kNIL | kTRUE | kFALSE | kANY | kUNTYPED | kTOP | kBOT | kINSTANCE | kBOOL | kSINGLETON
    | kTYPE | kMODULE | kPRIVATE | kPUBLIC | kEND | kINCLUDE | kEXTEND | kPREPEND
    | kATTRREADER | kATTRACCESSOR | kATTRWRITER | kDEF | kEXTENSION | kSELF | kINCOMPATIBLE
    | kUNCHECKED | kINTERFACE | kALIAS | kOUT | kIN | kOVERLOAD

  module_type_params:
      { result = nil }
    | kLBRACKET module_type_params0 kRBRACKET {
        val[1].each {|p| insert_bound_variable(p.name) }

        result = LocatedValue.new(value: val[1], location: val[0].location + val[2].location)
      }

  module_type_params0:
      module_type_param {
        result = Declarations::ModuleTypeParams.new()
        result.add(val[0])
      }
    | module_type_params0 kCOMMA module_type_param {
        result = val[0].add(val[2])
      }

  module_type_param:
      type_param_check type_param_variance tUIDENT {
        loc = case
              when l0 = val[0].location
                l0 + val[2].location
              when l1 = val[1].location
                l1 + val[2].location
              else
                val[2].location
              end
        loc = loc.with_children(
          required: { name: val[2].location },
          optional: { variance: val[1].location, unchecked: val[0].location }
        )
        result = Declarations::ModuleTypeParams::TypeParam.new(
          name: val[2].value.to_sym,
          variance: val[1].value,
          skip_validation: val[0].value,
          location: loc
        )
      }

  type_param_variance:
      { result = LocatedValue.new(value: :invariant, location: nil) }
    | kOUT { result = LocatedValue.new(value: :covariant, location: val[0].location) }
    | kIN { result = LocatedValue.new(value: :contravariant, location: val[0].location) }

  type_param_check:
      { result = LocatedValue.new(value: false, location: nil) }
    | kUNCHECKED { result = LocatedValue.new(value: true, location: val[0].location) }

  type_params:
      { result = nil }
    | kLBRACKET type_params0 kRBRACKET {
        val[1].each {|var| insert_bound_variable(var) }

        result = LocatedValue.new(value: val[1],
                                  location: val[0].location + val[2].location)
      }

  type_params0:
      tUIDENT {
        result = [val[0].value.to_sym]
      }
    | type_params0 kCOMMA tUIDENT {
        result = val[0].push(val[2].value.to_sym)
      }

  alias_member:
      annotations kALIAS method_name method_name {
        location = val[1].location + val[3].location
        location = location.with_children(
          required: { keyword: val[1].location, new_name: val[2].location, old_name: val[3].location },
          optional: { new_kind: nil, old_kind: nil }
        )
        result = Members::Alias.new(
          new_name: val[2].value.to_sym,
          old_name: val[3].value.to_sym,
          kind: :instance,
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }
    | annotations kALIAS kSELF kDOT method_name kSELF kDOT method_name {
        location = val[1].location + val[7].location
        location = location.with_children(
          required: { keyword: val[1].location, new_name: val[4].location, old_name: val[7].location },
          optional: {
            new_kind: val[2].location + val[3].location,
            old_kind: val[5].location + val[6].location
          }
        )
        result = Members::Alias.new(
          new_name: val[4].value.to_sym,
          old_name: val[7].value.to_sym,
          kind: :singleton,
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }

  type_decl:
      annotations kTYPE type_alias_name kEQ type {
        location = val[1].location + val[4].location
        location = location.with_children(
          required: { keyword: val[1].location, name: val[2].location, eq: val[3].location }
        )
        result = Declarations::Alias.new(
          name: val[2].value,
          type: val[4],
          annotations: val[0],
          location: location,
          comment: leading_comment(val[0].first&.location || location)
        )
      }

  const_decl:
      class_name kCOLON type {
        location = val[0].location + val[2].location
        location = location.with_children(
          required: { name: val[0].location, colon: val[1].location }
        )
        result = Declarations::Constant.new(name: val[0].value,
                                            type: val[2],
                                            location: location,
                                            comment: leading_comment(location))
      }
    | namespace tUKEYWORD type {
        location = (val[0] || val[1]).location + val[2].location

        lhs_loc = (val[0] || val[1]).location + val[1].location
        name_loc, colon_loc = split_kw_loc(lhs_loc)
        location = location.with_children(
          required: { name: name_loc, colon: colon_loc }
        )

        name = TypeName.new(name: val[1].value, namespace: val[0]&.value || Namespace.empty)
        result = Declarations::Constant.new(name: name,
                                            type: val[2],
                                            location: location,
                                            comment: leading_comment(location))
      }

  global_decl:
      tGLOBALIDENT kCOLON type {
        location = val[0].location + val[2].location
        location = location.with_children(
          required: { name: val[0].location, colon: val[1].location }
        )
        result = Declarations::Global.new(name: val[0].value.to_sym,
                                          type: val[2],
                                          location: location,
                                          comment: leading_comment(location))
      }

  type:
      simple_type
    | type kBAR type {
        types = case l = val[0]
                when Types::Union
                  l.types + [val[2]]
                else
                  [l, val[2]]
                end

        result = Types::Union.new(types: types, location: val[0].location + val[2].location)
      }
    | type kAMP type {
        types = case l = val[0]
                when Types::Intersection
                  l.types + [val[2]]
                else
                  [l, val[2]]
                end

        result = Types::Intersection.new(types: types,
                                         location: val[0].location + val[2].location)
      }

  simple_type:
      kVOID {
        result = Types::Bases::Void.new(location: val[0].location)
      }
    | kANY {
        RBS.logger.warn "`any` type is deprecated. Use `untyped` instead. (#{val[0].location.to_s})"
        result = Types::Bases::Any.new(location: val[0].location)
      }
    | kUNTYPED {
        result = Types::Bases::Any.new(location: val[0].location)
      }
    | kBOOL {
        result = Types::Bases::Bool.new(location: val[0].location)
      }
    | kNIL {
        result = Types::Bases::Nil.new(location: val[0].location)
      }
    | kTOP {
        result = Types::Bases::Top.new(location: val[0].location)
      }
    | kBOT {
        result = Types::Bases::Bottom.new(location: val[0].location)
      }
    | kSELF {
        result = Types::Bases::Self.new(location: val[0].location)
      }
    | kSELFQ {
        result = Types::Optional.new(type: Types::Bases::Self.new(location: val[0].location),
                                     location: val[0].location)
      }
    | kINSTANCE {
        result = Types::Bases::Instance.new(location: val[0].location)
      }
    | kCLASS {
        result = Types::Bases::Class.new(location: val[0].location)
      }
    | kTRUE {
        result = Types::Literal.new(literal: true, location: val[0].location)
      }
    | kFALSE {
        result = Types::Literal.new(literal: false, location: val[0].location)
      }
    | tINTEGER {
        result = Types::Literal.new(literal: val[0].value, location: val[0].location)
      }
    | tSTRING {
        result = Types::Literal.new(literal: val[0].value, location: val[0].location)
      }
    | tSYMBOL {
        result = Types::Literal.new(literal: val[0].value, location: val[0].location)
      }
    | qualified_name {
        name = val[0].value
        args = []
        location = val[0].location

        case
        when name.class?
          if is_bound_variable?(name.name)
            result = Types::Variable.new(name: name.name, location: location)
          else
            location = location.with_children(
              required: { name: val[0].location },
              optional: { args: nil }
            )
            result = Types::ClassInstance.new(name: name, args: args, location: location)
          end
        when name.alias?
          location = location.with_children(
            required: { name: val[0].location },
            optional: { args: nil }
          )
          result = Types::Alias.new(name: name, location: location)
        when name.interface?
          location = location.with_children(
            required: { name: val[0].location },
            optional: { args: nil }
          )
          result = Types::Interface.new(name: name, args: args, location: location)
        end
      }
    | qualified_name kLBRACKET type_list kRBRACKET {
        name = val[0].value
        args = val[2]
        location = val[0].location + val[3].location

        case
        when name.class?
          if is_bound_variable?(name.name)
            raise SemanticsError.new("#{name.name} is type variable and cannot be applied", subject: name, location: location)
          end
          location = location.with_children(
            required: { name: val[0].location },
            optional: { args: val[1].location + val[3].location }
          )
          result = Types::ClassInstance.new(name: name, args: args, location: location)
        when name.interface?
          location = location.with_children(
            required: { name: val[0].location },
            optional: { args: val[1].location + val[3].location }
          )
          result = Types::Interface.new(name: name, args: args, location: location)
        else
          raise SyntaxError.new(token_str: "kLBRACKET", error_value: val[1])
        end
      }
    | kLBRACKET kRBRACKET {
        location = val[0].location + val[1].location
        result = Types::Tuple.new(types: [], location: location)
      }
    | kLBRACKET type_list comma_opt kRBRACKET {
        location = val[0].location + val[3].location
        types = val[1]
        result = Types::Tuple.new(types: types, location: location)
      }
    | kLPAREN type kRPAREN {
        type = val[1].dup
        type.instance_eval do
          @location = val[0].location + val[2].location
        end
        result = type
      }
    | kSINGLETON kLPAREN class_name kRPAREN {
        location = val[0].location + val[3].location
        location = location.with_children(
          required: { name: val[2].location }
        )
        result = Types::ClassSingleton.new(name: val[2].value, location: location)
      }
    | kHAT proc_type {
        type, block = val[1].value
        result = Types::Proc.new(type: type, block: block, location: val[0].location + val[1].location)
      }
    | simple_type kQUESTION {
        result = Types::Optional.new(type: val[0], location: val[0].location + val[1].location)
      }
    | record_type

  type_list:
      type {
        result = [val[0]]
      }
    | type_list kCOMMA type {
        result = val[0] + [val[2]]
      }

  record_type:
      kLBRACE record_fields comma_opt kRBRACE {
        result = Types::Record.new(
          fields: val[1],
          location: val[0].location + val[3].location
        )
      }

  record_fields:
      record_field {
        result = val[0]
      }
    | record_fields kCOMMA record_field {
        result = val[0].merge!(val[2])
      }

  record_field:
      tSYMBOL kFATARROW type {
        result = { val[0].value => val[2] }
      }
    | tSTRING kFATARROW type {
        result = { val[0].value => val[2] }
      }
    | tINTEGER kFATARROW type {
        result = { val[0].value => val[2] }
      }
    | keyword type {
        result = { val[0].value => val[1] }
      }
    | identifier_keywords kCOLON type {
        result = { val[0].value => val[2] }
      }
    | tQUOTEDIDENT kCOLON type {
        result = { val[0].value => val[2] }
      }
    | tQUOTEDMETHOD kCOLON type {
        result = { val[0].value => val[2] }
      }

  keyword_name:
      keyword
    | identifier_keywords kCOLON {
        result = val[0]
      }

  keyword: tLKEYWORD | tUKEYWORD | tLKEYWORD_Q_E | tUKEYWORD_Q_E

  proc_type:
      params_opt block kARROW simple_type {
        location = (val[0] || val[1] || val[2]).location + val[3].location

        params = val[0]&.value || [[], [], nil, [], {}, {}, nil]

        type = Types::Function.new(
          required_positionals: params[0],
          optional_positionals: params[1],
          rest_positionals: params[2],
          trailing_positionals: params[3],
          required_keywords: params[4],
          optional_keywords: params[5],
          rest_keywords: params[6],
          return_type: val[3]
        )

        block = val[1].value

        result = LocatedValue.new(value: [type, block], location: location)
      }
    | simple_function_type {
        result = LocatedValue.new(value: [val[0].value, nil], location: val[0].location)
      }

  simple_function_type:
      kLPAREN params kRPAREN kARROW simple_type {
        location = val[0].location + val[4].location
        type = Types::Function.new(
          required_positionals: val[1][0],
          optional_positionals: val[1][1],
          rest_positionals: val[1][2],
          trailing_positionals: val[1][3],
          required_keywords: val[1][4],
          optional_keywords: val[1][5],
          rest_keywords: val[1][6],
          return_type: val[4],
        )

        result = LocatedValue.new(value: type, location: location)
      }
    | kARROW simple_type {
        location = val[0].location + val[1].location
        type = Types::Function.new(
          required_positionals: [],
          optional_positionals: [],
          rest_positionals: nil,
          trailing_positionals: [],
          required_keywords: {},
          optional_keywords: {},
          rest_keywords: nil,
          return_type: val[1]
        )

        result = LocatedValue.new(value: type, location: location)
      }

  params:
      required_positional kCOMMA params {
        result = val[2]
        result[0].unshift(val[0])
      }
    | required_positional {
        result = empty_params_result
        result[0].unshift(val[0])
      }
    | optional_positional_params

  optional_positional_params:
      optional_positional kCOMMA optional_positional_params {
        result = val[2]
        result[1].unshift(val[0])
      }
    | optional_positional {
        result = empty_params_result
        result[1].unshift(val[0])
      }
    | rest_positional_param

  rest_positional_param:
      rest_positional kCOMMA trailing_positional_params {
        result = val[2]
        result[2] = val[0]
      }
    | rest_positional {
        result = empty_params_result
        result[2] = val[0]
      }
    | trailing_positional_params

  trailing_positional_params:
      required_positional kCOMMA trailing_positional_params {
        result = val[2]
        result[3].unshift(val[0])
      }
    | required_positional {
        result = empty_params_result
        result[3].unshift(val[0])
      }
    | keyword_params

  keyword_params:
      {
        result = empty_params_result
      }
    | required_keyword kCOMMA keyword_params {
        result = val[2]
        result[4].merge!(val[0])
      }
    | required_keyword {
        result = empty_params_result
        result[4].merge!(val[0])
      }
    | optional_keyword kCOMMA keyword_params {
        result = val[2]
        result[5].merge!(val[0])
      }
    | optional_keyword {
        result = empty_params_result
        result[5].merge!(val[0])
      }
    | rest_keyword {
        result = empty_params_result
        result[6] = val[0]
      }

  required_positional:
      type var_name_opt {
        loc = val[0].location
        if var_name = val[1]
          loc = loc + var_name.location
        end
        loc = loc.with_children(optional: { name: var_name&.location })

        result = Types::Function::Param.new(
          type: val[0],
          name: var_name&.value&.to_sym,
          location: loc
        )
      }

  optional_positional:
      kQUESTION type var_name_opt {
        loc = val[0].location + val[1].location
        if var_name = val[2]
          loc = loc + var_name.location
        end
        loc = loc.with_children(optional: { name: var_name&.location })

        result = Types::Function::Param.new(
          type: val[1],
          name: val[2]&.value&.to_sym,
          location: loc
        )
      }

  rest_positional:
      kSTAR type var_name_opt {
        loc = val[0].location + val[1].location
        if var_name = val[2]
          loc = loc + var_name.location
        end
        loc = loc.with_children(optional: { name: var_name&.location })

        result = Types::Function::Param.new(
          type: val[1],
          name: val[2]&.value&.to_sym,
          location: loc
        )
      }

  required_keyword:
      keyword_name type var_name_opt {
        loc = val[0].location + val[1].location
        if var_name = val[2]
          loc = loc + var_name.location
        end

        loc = loc.with_children(optional: { name: var_name&.location })

        param = Types::Function::Param.new(
          type: val[1],
          name: val[2]&.value&.to_sym,
          location: loc
        )
        result = { val[0].value => param }
      }

  optional_keyword:
      kQUESTION keyword_name type var_name_opt {
        loc = val[0].location + val[2].location
        if var_name = val[3]
          loc = loc + var_name.location
        end

        loc = loc.with_children(optional: { name: var_name&.location })

        param = Types::Function::Param.new(
          type: val[2],
          name: val[3]&.value&.to_sym,
          location: loc
        )
        result = { val[1].value => param }
      }

  rest_keyword:
      kSTAR2 type var_name_opt {
        loc = val[0].location + val[1].location
        if var_name = val[2]
          loc = loc + var_name.location
        end

        loc = loc.with_children(optional: { name: var_name&.location })

        result = Types::Function::Param.new(
          type: val[1],
          name: val[2]&.value&.to_sym,
          location: loc
        )
      }

  var_name_opt:
    | tLIDENT | tINTERFACEIDENT | tQUOTEDIDENT | tUNDERSCOREIDENT

  qualified_name:
      namespace simple_name {
        namespace = val[0]&.value || Namespace.empty
        name = val[1].value.to_sym
        type_name = TypeName.new(namespace: namespace, name: name)
        location = (loc0 = val[0]&.location) ? loc0 + val[1].location : val[1].location
        result = LocatedValue.new(value: type_name, location: location)
      }

  simple_name:
      tUIDENT | tLIDENT | tINTERFACEIDENT

  interface_name:
      namespace tINTERFACEIDENT {
        namespace = val[0]&.value || Namespace.empty
        name = val[1].value.to_sym
        type_name = TypeName.new(namespace: namespace, name: name)
        location = (loc0 = val[0]&.location) ? loc0 + val[1].location : val[1].location
        result = LocatedValue.new(value: type_name, location: location)
      }

  class_name:
      namespace tUIDENT {
        namespace = val[0]&.value || Namespace.empty
        name = val[1].value.to_sym
        type_name = TypeName.new(namespace: namespace, name: name)
        location = (loc0 = val[0]&.location) ? loc0 + val[1].location : val[1].location
        result = LocatedValue.new(value: type_name, location: location)
      }

  type_alias_name:
      namespace tLIDENT {
        namespace = val[0]&.value || Namespace.empty
        name = val[1].value.to_sym
        type_name = TypeName.new(namespace: namespace, name: name)
        location = (loc0 = val[0]&.location) ? loc0 + val[1].location : val[1].location
        result = LocatedValue.new(value: type_name, location: location)
      }


  namespace:
      {
        result = nil
      }
    | kCOLON2 {
        result = LocatedValue.new(value: Namespace.root, location: val[0].location)
      }
    | kCOLON2 tNAMESPACE {
        namespace = Namespace.parse(val[1].value).absolute!
        result = LocatedValue.new(value: namespace, location: val[0].location + val[1].location)
      }
    | tNAMESPACE {
        namespace = Namespace.parse(val[0].value)
        result = LocatedValue.new(value: namespace, location: val[0].location)
      }

  comma_opt:
      kCOMMA | # empty

end

---- inner

Types = RBS::Types
Namespace = RBS::Namespace
TypeName = RBS::TypeName
Declarations = RBS::AST::Declarations
Members = RBS::AST::Members
MethodType = RBS::MethodType
Annotation = RBS::AST::Annotation

class LocatedValue
  attr_reader :location
  attr_reader :value

  def initialize(location:, value:)
    @location = location
    @value = value
  end
end

attr_reader :input
attr_reader :buffer
attr_reader :eof_re

def initialize(type, buffer:, eof_re:)
  super()
  @type = type
  @buffer = buffer
  @input = CharScanner.new(buffer.content)
  @eof_re = eof_re
  @eof = false
  @bound_variables_stack = []
  @comments = {}
  @ascii_only = buffer.content.ascii_only?
end

def start_merged_variables_scope
  set = @bound_variables_stack.last&.dup || Set.new
  @bound_variables_stack.push set
end

def start_new_variables_scope
  @bound_variables_stack.push Set.new
end

def reset_variable_scope
  @bound_variables_stack.pop
end

def insert_bound_variable(var)
  @bound_variables_stack.last << var
end

def is_bound_variable?(var)
  (@bound_variables_stack.last || Set.new).member?(var)
end

def self.parse_signature(input, eof_re: nil)
  case input
  when RBS::Buffer
    buffer = input
  else
    buffer = RBS::Buffer.new(name: nil, content: input.to_s)
  end

  self.new(:SIGNATURE, buffer: buffer, eof_re: eof_re).do_parse
end

def self.parse_type(input, variables: [], eof_re: nil)
  case input
  when RBS::Buffer
    buffer = input
  else
    buffer = RBS::Buffer.new(name: nil, content: input.to_s)
  end

  self.new(:TYPE, buffer: buffer, eof_re: eof_re).yield_self do |parser|
    parser.start_new_variables_scope

    variables.each do |var|
      parser.insert_bound_variable var
    end

    parser.do_parse
  ensure
    parser.reset_variable_scope
  end
end

def self.parse_method_type(input, variables: [], eof_re: nil)
  case input
  when RBS::Buffer
    buffer = input
  else
    buffer = RBS::Buffer.new(name: nil, content: input.to_s)
  end

  self.new(:METHODTYPE, buffer: buffer, eof_re: eof_re).yield_self do |parser|
    parser.start_new_variables_scope

    variables.each do |var|
      parser.insert_bound_variable var
    end

    parser.do_parse
  ensure
    parser.reset_variable_scope
  end
end

def leading_comment(location)
  @comments[location.start_line-1]
end

def push_comment(string, location)
  if (comment = leading_comment(location)) && comment.location.start_column == location.start_column
    comment.concat(string: "#{string}\n", location: location)
    @comments[comment.location.end_line] = comment
  else
    new_comment = AST::Comment.new(string: "#{string}\n", location: location)
    @comments[new_comment.location.end_line] = new_comment
  end
end

def new_token(type, value = input.matched)
  charpos = charpos(input)
  matched = input.matched

  if matched
    start_index = charpos - matched.size
    end_index = charpos

    location = RBS::Location.new(buffer: buffer,
                                 start_pos: start_index,
                                 end_pos: end_index)

    [type, LocatedValue.new(location: location, value: value)]
  else
    # scanner hasn't matched yet
    [false, nil]
  end
end

def charpos(scanner)
  scanner.charpos
end

def empty_params_result
  [
    [],
    [],
    nil,
    [],
    {},
    {},
    nil
  ]
end

KEYWORDS = {
  "class" => :kCLASS,
  "type" => :kTYPE,
  "def" => :kDEF,
  "self" => :kSELF,
  "void" => :kVOID,
  "any" => :kANY,
  "untyped" => :kUNTYPED,
  "top" => :kTOP,
  "bot" => :kBOT,
  "instance" => :kINSTANCE,
  "bool" => :kBOOL,
  "nil" => :kNIL,
  "true" => :kTRUE,
  "false" => :kFALSE,
  "singleton" => :kSINGLETON,
  "interface" => :kINTERFACE,
  "end" => :kEND,
  "include" => :kINCLUDE,
  "extend" => :kEXTEND,
  "prepend" => :kPREPEND,
  "module" => :kMODULE,
  "attr_reader" => :kATTRREADER,
  "attr_writer" => :kATTRWRITER,
  "attr_accessor" => :kATTRACCESSOR,
  "public" => :kPUBLIC,
  "private" => :kPRIVATE,
  "alias" => :kALIAS,
  "extension" => :kEXTENSION,
  "incompatible" => :kINCOMPATIBLE,
  "unchecked" => :kUNCHECKED,
  "overload" => :kOVERLOAD,
  "out" => :kOUT,
  "in" => :kIN,
}
KEYWORDS_RE = /#{Regexp.union(*KEYWORDS.keys)}\b/

PUNCTS = {
  "===" => :tOPERATOR,
  "==" => :tOPERATOR,
  "=~" => :tOPERATOR,
  "!~" => :tOPERATOR,
  "!=" => :tOPERATOR,
  ">=" => :tOPERATOR,
  "<<" => :tOPERATOR,
  "<=>" => :tOPERATOR,
  "<=" => :tOPERATOR,
  ">>" => :tOPERATOR,
  ">" => :tOPERATOR,
  "~" => :tOPERATOR,
  "+@" => :tOPERATOR,
  "+" => :tOPERATOR,
  "[]=" => :tOPERATOR,
  "[]" => :tOPERATOR,
  "::" => :kCOLON2,
  ":" => :kCOLON,
  "(" => :kLPAREN,
  ")" => :kRPAREN,
  "[" => :kLBRACKET,
  "]" => :kRBRACKET,
  "{" => :kLBRACE,
  "}" => :kRBRACE,
  "," => :kCOMMA,
  "|" => :kBAR,
  "&" => :kAMP,
  "^" => :kHAT,
  "->" => :kARROW,
  "=>" => :kFATARROW,
  "=" => :kEQ,
  "?" => :kQUESTION,
  "!" => :kEXCLAMATION,
  "**" => :kSTAR2,
  "*" => :kSTAR,
  "..." => :kDOT3,
  "." => :kDOT,
  "<" => :kLT,
  "-@" => :tOPERATOR,
  "-" => :tOPERATOR,
  "/" => :tOPERATOR,
  "`" => :tOPERATOR,
  "%" => :tOPERATOR,
}
PUNCTS_RE = Regexp.union(*PUNCTS.keys)

ANNOTATION_RE = Regexp.union(/%a\{.*?\}/,
                             /%a\[.*?\]/,
                             /%a\(.*?\)/,
                             /%a\<.*?\>/,
                             /%a\|.*?\|/)

escape_sequences = %w[a b e f n r s t v "].map { |l| "\\\\#{l}" }
DBL_QUOTE_STR_ESCAPE_SEQUENCES_RE = /(#{escape_sequences.join("|")})/

def next_token
  if @type
    type = @type
    @type = nil
    return [:"type_#{type}", nil]
  end

  return new_token(false, '') if @eof

  while true
    return new_token(false, '') if input.eos?

    case
    when input.scan(/\s+/)
      # skip
    when input.scan(/#(( *)|( ?(?<string>.*)))\n/)
      charpos = charpos(input)
      start_index = charpos - input.matched.size
      end_index = charpos-1

      location = RBS::Location.new(buffer: buffer,
                                               start_pos: start_index,
                                               end_pos: end_index)

      push_comment input[:string] || "", location
    else
      break
    end
  end

  case
  when eof_re && input.scan(eof_re)
    @eof = true
    [:tEOF, input.matched]
  when input.scan(/`[a-zA-Z_]\w*`/)
    s = input.matched.yield_self {|s| s[1, s.length-2] }
    new_token(:tQUOTEDIDENT, s)
  when input.scan(/`(\\`|[^` :])+`/)
    s = input.matched.yield_self {|s| s[1, s.length-2] }.gsub(/\\`/, '`')
    new_token(:tQUOTEDMETHOD, s)
  when input.scan(ANNOTATION_RE)
    s = input.matched.yield_self {|s| s[3, s.length-4] }.strip
    new_token(:tANNOTATION, s)
  when input.scan(/self\?/)
    new_token(:kSELFQ, "self?")
  when input.scan(/(([a-zA-Z]\w*)|(_\w+))=/)
    new_token(:tWRITE_ATTR)
  when input.scan(KEYWORDS_RE)
    new_token(KEYWORDS[input.matched], input.matched.to_sym)
  when input.scan(/:((@{,2}|\$)?\w+(\?|\!)?|[|&\/%~`^]|<=>|={2,3}|=~|[<>]{2}|[<>]=?|[-+]@?|\*{1,2}|\[\]=?|![=~]?)\b?/)
    s = input.matched.yield_self {|s| s[1, s.length] }.to_sym
    new_token(:tSYMBOL, s)
  when input.scan(/[+-]?\d[\d_]*/)
    new_token(:tINTEGER, input.matched.to_i)
  when input.scan(PUNCTS_RE)
    new_token(PUNCTS[input.matched])
  when input.scan(/(::)?([A-Z]\w*::)+/)
    new_token(:tNAMESPACE)
  when input.scan(/[a-z_]\w*:/)
    new_token(:tLKEYWORD, input.matched.chop.to_sym)
  when input.scan(/[a-z_]\w*[?!]:/)
    new_token(:tLKEYWORD_Q_E, input.matched.chop.to_sym)
  when input.scan(/[A-Z]\w*:/)
    new_token(:tUKEYWORD, input.matched.chop.to_sym)
  when input.scan(/[A-Z]\w*[?!]:/)
    new_token(:tUKEYWORD_Q_E, input.matched.chop.to_sym)
  when input.scan(/\$[A-Za-z_]\w*/)
    new_token(:tGLOBALIDENT)
  when input.scan(/@[a-zA-Z_]\w*/)
    new_token(:tIVAR, input.matched.to_sym)
  when input.scan(/@@[a-zA-Z_]\w*/)
    new_token(:tCLASSVAR, input.matched.to_sym)
  when input.scan(/_[A-Z]\w*\b/)
    new_token(:tINTERFACEIDENT)
  when input.scan(/[A-Z]\w*\b/)
    new_token(:tUIDENT)
  when input.scan(/[a-z]\w*\b/)
    new_token(:tLIDENT)
  when input.scan(/_[a-z]\w*\b/)
    new_token(:tUNDERSCOREIDENT)
  when input.scan(/"(\\"|[^"])*"/)
    s = input.matched.yield_self {|s| s[1, s.length - 2] }
                     .gsub(DBL_QUOTE_STR_ESCAPE_SEQUENCES_RE) do |match|
                       case match
                       when '\\a' then "\a"
                       when '\\b' then "\b"
                       when '\\e' then "\e"
                       when '\\f' then "\f"
                       when '\\n' then "\n"
                       when '\\r' then "\r"
                       when '\\s' then "\s"
                       when '\\t' then "\t"
                       when '\\v' then "\v"
                       when '\\"' then '"'
                       end
                     end
    new_token(:tSTRING, s)
  when input.scan(/'(\\'|[^'])*'/)
    s = input.matched.yield_self {|s| s[1, s.length - 2] }.gsub(/\\'/, "'")
    new_token(:tSTRING, s)
  else
    text = input.peek(10)
    start_index = charpos(input)
    end_index = start_index + text.length
    location = RBS::Location.new(buffer: buffer, start_pos: start_index, end_pos: end_index)
    raise LexerError.new(input: text, location: location)
  end
end

def on_error(token_id, error_value, value_stack)
  raise SyntaxError.new(token_str: token_to_str(token_id), error_value: error_value, value_stack: value_stack)
end

def split_kw_loc(loc)
  buf = loc.buffer
  start_pos = loc.start_pos
  end_pos = loc.end_pos
  [
    Location.new(buffer: buf, start_pos: start_pos, end_pos: end_pos - 1),
    Location.new(buffer: buf, start_pos: end_pos - 1, end_pos: end_pos)
  ]
end

class SyntaxError < ParsingError
  attr_reader :token_str, :error_value, :value_stack

  def initialize(token_str:, error_value:, value_stack: nil)
    @token_str = token_str
    @error_value = error_value
    @value_stack = value_stack

    super "parse error on value: #{error_value.inspect} (#{token_str})"
  end
end

class SemanticsError < ParsingError
  attr_reader :subject, :location, :original_message

  def initialize(message, subject:, location:)
    @subject = subject
    @location = location
    @original_message = message

    super "parse error on #{location}: #{message}"
  end
end

class LexerError < ParsingError
  attr_reader :location, :input

  def initialize(input:, location:)
    @input = input
    @location = location

    super "Unexpected string: #{input}..."
  end
end

---- footer
