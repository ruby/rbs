# frozen_string_literal: true

require 'rbs'

class RDoc::Parser::RBS < RDoc::Parser
  parse_files_matching(/\.rbs$/)

  def initialize(top_level, file_name, content, options, stats)
    super
  end

  def scan
    ast = ::RBS::Parser.parse_signature(@content)
    ast.each do |decl|
      parse_member(decl: decl, context: @top_level)
    end
    klass = @top_level.add_class(RDoc::NormalClass, 'Hello')
    comment = RDoc::Comment.new('Hello documentation', @top_level)
    klass.add_comment(comment, @top_level)
    @stats.add_class(klass)
  end

  def parse_member(decl:, context:, outer_name: nil)
    case decl
    when ::RBS::AST::Declarations::Class
      parse_class_decl(decl: decl, context: context, outer_name: outer_name)
    when ::RBS::AST::Declarations::Module
      parse_module_decl(decl: decl, context: context, outer_name: outer_name)
    when ::RBS::AST::Declarations::Constant
      context = @top_level.find_class_or_module outer_name.to_s if outer_name
      parse_constant_decl(decl: decl, context: context, outer_name: outer_name)
    when ::RBS::AST::Members::MethodDefinition
      context = @top_level.find_class_or_module outer_name.to_s if outer_name
      parse_method_decl(decl: decl, context: context, outer_name: outer_name)
    end
  end

  def parse_class_decl(decl:, context:, outer_name: nil)
    full_name = fully_qualified_name(outer_name: outer_name, decl: decl)
    klass = context.add_class(RDoc::NormalClass, full_name.to_s)
    klass.add_comment(construct_comment(context: context, comment: decl.comment.string), context) if decl.comment
    decl.members.each { |member| parse_member(decl: member, context: context, outer_name: full_name) }
  end

  def parse_module_decl(decl:, context:, outer_name: nil)
    full_name = fully_qualified_name(outer_name: outer_name, decl: decl)
    kmodule = context.add_module(RDoc::NormalModule, full_name.to_s)
    kmodule.add_comment(construct_comment(context: context, comment: decl.comment.string), context) if decl.comment
    decl.members.each { |member| parse_member(decl: member, context: context, outer_name: outer_name) }
  end

  def parse_constant_decl(decl:, context:, outer_name: nil)
    comment = decl.comment ? construct_comment(context: context, comment: decl.comment.string) : nil
    constant = RDoc::Constant.new(decl.name.to_s, decl.type.to_s, comment)
    context.add_constant(constant)
  end

  def parse_method_decl(decl:, context:, outer_name: nil)
    method = RDoc::AnyMethod.new(nil, decl.name.to_s)
    method.singleton = decl.singleton?
    method.visibility = decl.visibility
    method.call_seq = decl.types.map { |type| "#{decl.name.to_s}#{type.to_s}" }.join("\n")
    method.comment = construct_comment(context: context, comment: decl.comment.string) if decl.comment
    context.add_method(method)
  end

  private

  def construct_comment(context:, comment:)
    comment = RDoc::Comment.new(comment, context)
    comment.format = "markdown"
    comment
  end

  def fully_qualified_name(outer_name:, decl:)
    if outer_name
      (outer_name + decl.name)
    else
      decl.name
    end
  end
end
