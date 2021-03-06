#!/usr/bin/env ruby
require 'win32ole'

class << Hash
  def create(keys, values)
    self[*keys.zip(values).flatten]
  end
end

class SqlServer
  attr_accessor :connection

  # Creates a Sql Server Connection
  # * :host => The server name or IP.
  # * :user_name => SQL user.
  # * :password => The password for user_name.
  # * :database => Database to connect to on the host.
  # * :timeout => The seconds to wait for a query/commant to run.
  def initialize(params = {})
    # Set the connection parameters
    params = { :host => nil, :user_name => nil, :password => nil,
               :database => nil, :timeout => nil }.merge!(params)
    @timeout = params[:timeout]
    @connection = open(params)
  end
  
  # Executes the sepecified query and returns the results in a hash.
  def query(sql)
    # Create an instance of an ADO Recordset
    recordset = WIN32OLE.new('ADODB.Recordset')
    
    # Open the recordset, using an SQL statement and the
    # existing ADO connection
    recordset.Open(sql, @connection)
    
    # Create and populate an array of field names
    fields = []
    data = []
    recordset.Fields.each do |field|
      fields << field.Name
    end
    
    begin
      # Move to the first record/row, if any exist
      recordset.MoveFirst
      
      # Grab all records
      data = recordset.GetRows
    rescue Exception => e
      # Do nothing, it's an empty recordset
    end
    recordset.Close
    
    # An ADO Recordset's GetRows method returns an array 
    # of columns, so we'll use the transpose method to 
    # convert it to an array of rows
    data = data.transpose
    
    result_set = []
    data.each { |row| result_set << Hash.create(fields, row) }
    
    return result_set
  end
  
  # Executes the specfied SQL command.
  def execute_command(sql_statement)
    # Create an instance of an ADO COmmand
    command = WIN32OLE.new('ADODB.Command')
    
    # Execute the SQL statement using the existing ADO connection
    command.ActiveConnection = @connection
    command.CommandText=sql_statement
    command.CommandTimeout = @timeout unless @timeout.nil?
    command.Execute
  end
  
  # Closes the connection to the SQL Server.
  def close
    @connection.Close
  end
  
  private
  
  def open(params)
    connection_string =  "Provider=SQLNCLI;"
    connection_string << "Server=#{params[:host]};"
    connection_string << "Uid=#{params[:user_name]};"
    connection_string << "Pwd=#{params[:password]};"
    connection_string << "Database=#{params[:database]};"
    
    connection = WIN32OLE.new('ADODB.Connection')
    connection.Open(connection_string)
    connection.CommandTimeout = @timeout unless @timeout.nil?
    
    return connection
  end
end