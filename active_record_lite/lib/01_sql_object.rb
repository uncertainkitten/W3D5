require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  attr_accessor :columns

  def self.columns
    return @columns unless @columns == nil
    columns = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      '#{self.table_name}'
    LIMIT
      0
    SQL

    @columns = columns[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns

    @columns.each do |column|
      define_method("#{column}") do
        @attributes[:"#{column}"]
      end

      define_method("#{column}=") do |value|
        attributes
        @attributes[:"#{column}"] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    all_obj = []
    results.each do |table_hash|
      all_obj << self.itself.new(table_hash)
    end

    all_obj
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      '#{self.table_name}'
    WHERE
      id = ?
    SQL

    self.new(result.first) unless result == []
  end

  def initialize(params = {})
    params.each do |attr_name, attr_value|
      attr_s = attr_name.to_sym
      raise "unknown attribute '#{attr_s}'" unless self.class.columns.include?(attr_s)

      self.send("#{attr_s}=", attr_value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    result = self.class.columns.map do |column|
      self.send(:"#{column}")
    end

    result
  end

  def insert
    args = self.attribute_values[1..-1]
    col_names = self.class.columns.join(",")
    count = args.length
    question_arks = ["?"] * count
    question_marks = question_arks.join(",")

    DBConnection.execute(<<-SQL, *args)
    INSERT INTO
      #{@table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
