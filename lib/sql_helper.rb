# encoding: utf-8
module SqlHelper

  # WARNING: At present there is no santizing going on here, do that before you get tot his point

  # args: (:optional_table_name, *values)
  # SELECT id FROM foo WHERE name = <result>
  def self.where_scope_for_name(*args)
    @table = args.shift.to_s if args.first.class.name == "Symbol" # better pattern for this likely available
    col = "#{ (@table ? "#{@table}." : '') }name"
    return "#{col} = -1" if args.size == 0
    "(" + args.flatten.collect{|n| "(#{col} = \"#{n}\")"}.join(" OR ") + ")"
  end

end
