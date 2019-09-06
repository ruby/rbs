# The [GC](GC) module provides an interface to Ruby’s
# mark and sweep garbage collection mechanism.
# 
# Some of the underlying methods are also available via the
# [ObjectSpace](https://ruby-doc.org/core-2.6.3/ObjectSpace.html) module.
# 
# You may obtain information about the operation of the
# [GC](GC) through
# [GC::Profiler](https://ruby-doc.org/core-2.6.3/GC/Profiler.html).
module GC
  # The number of times [GC](GC.downloaded.ruby_doc) occurred.
  # 
  # It returns the number of times [GC](GC.downloaded.ruby_doc) occurred
  # since the process started.
  def self.count: () -> Integer

  # Disables garbage collection, returning `true` if garbage collection was
  # already disabled.
  # 
  # ```ruby
  # GC.disable   #=> false
  # GC.disable   #=> true
  # ```
  def self.disable: () -> bool

  # Enables garbage collection, returning `true` if garbage collection was
  # previously disabled.
  # 
  # ```ruby
  # GC.disable   #=> false
  # GC.enable    #=> true
  # GC.enable    #=> false
  # ```
  def self.enable: () -> bool

  def self.start: (?full_mark: bool full_mark, ?immediate_sweep: bool immediate_sweep) -> NilClass

  # Returns a [Hash](https://ruby-doc.org/core-2.6.3/Hash.html) containing
  # information about the [GC](GC.downloaded.ruby_doc).
  # 
  # The hash includes information about internal statistics about
  # [GC](GC.downloaded.ruby_doc) such as:
  # 
  # ```ruby
  # {
  #     :count=>0,
  #     :heap_allocated_pages=>24,
  #     :heap_sorted_length=>24,
  #     :heap_allocatable_pages=>0,
  #     :heap_available_slots=>9783,
  #     :heap_live_slots=>7713,
  #     :heap_free_slots=>2070,
  #     :heap_final_slots=>0,
  #     :heap_marked_slots=>0,
  #     :heap_eden_pages=>24,
  #     :heap_tomb_pages=>0,
  #     :total_allocated_pages=>24,
  #     :total_freed_pages=>0,
  #     :total_allocated_objects=>7796,
  #     :total_freed_objects=>83,
  #     :malloc_increase_bytes=>2389312,
  #     :malloc_increase_bytes_limit=>16777216,
  #     :minor_gc_count=>0,
  #     :major_gc_count=>0,
  #     :remembered_wb_unprotected_objects=>0,
  #     :remembered_wb_unprotected_objects_limit=>0,
  #     :old_objects=>0,
  #     :old_objects_limit=>0,
  #     :oldmalloc_increase_bytes=>2389760,
  #     :oldmalloc_increase_bytes_limit=>16777216
  # }
  # ```
  # 
  # The contents of the hash are implementation specific and may be changed
  # in the future.
  # 
  # This method is only expected to work on C Ruby.
  def self.stat: (?::Hash[Symbol, Integer] arg0) -> ::Hash[Symbol, Integer]
               | (?Symbol arg0) -> Integer

  # Returns current status of [GC](GC.downloaded.ruby_doc) stress mode.
  def self.stress: () -> (Integer | TrueClass | FalseClass)
end

GC::INTERNAL_CONSTANTS: Hash

GC::OPTS: Array

module GC::Profiler
  def self.clear: () -> void

  def self.disable: () -> void

  def self.enable: () -> void

  def self.enabled?: () -> bool

  def self.raw_data: () -> ::Array[::Hash[Symbol, any]]

  def self.report: (?IO io) -> void

  def self.result: () -> String

  def self.total_time: () -> Float
end
