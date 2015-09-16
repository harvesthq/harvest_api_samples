########################################################################
# 
# harvest-sample.rb
#
# Basic API demo. Use this sample as a starting point on how to
# connect, authenticate, and send requests to the Harvest API and
# handle the API throttle limit. This is not a libary, if you want one
# for Ruby, we recommend investigating ActiveResource::Base.
#
# To execute this sample, save this file to your computer and 
# run the following command from your console: 
#
#   ruby harvest-sample.rb
#
# You will then see output for the series of action scripted below.
#
# You can also use this as an inspiration for your own integration in
# another language. Basically you just need to send HTTP requests, a
# fairly common task that can be accomplished from nearly all programming
# languages. We receive requests from Python, Javascript, PHP, Perl,
# Java, C# and others.
#
# The full HARVEST API documentation can be found at:
#
#   http://getharvest.com/api
#
# Please review the documentation before sending in your questions. 
#


########################################################################
#
# First set some variables specific to your account.
#

# Insert your subdomain i.e. subdomain.harvestapp.com
SUBDOMAIN        = 'subdomain'

# Your email. Note that features hidden from non-administrator
# accounts on the WEB UI will be inaccessible in the API as well. The
# full API is available to users with admin privileges only!
ACCOUNT_EMAIL    =  'email@server.com'

# Your password. Harvest uses HTTP Basic Auth.
ACCOUNT_PASSWORD =  'password'

# Your application should send an unique User Agent value out of
# politeness.
USER_AGENT       = 'Be Polite Please Fill This Out'

# Business accounts have ssl support enabled. Set this to false if your
# WEB UI is accessible via http:// instead of https://. Note that
# Harvest will redirect you to the proper protocol regardless of
# this. You just need to handle the redirection pragmatically. This
# sample does this, your implementation should save the last known
# protocol to avoid increased latency.
HAS_SSL          = true



########################################################################
#
# Define a basic client.
#



# everything is in utf8
$KCODE = 'u'

require 'base64'
require 'bigdecimal'
require 'date'
require 'jcode'
require 'net/http'
require 'net/https'
require 'time'

class Harvest

  def initialize
    @company             = SUBDOMAIN
    @preferred_protocols = [HAS_SSL, ! HAS_SSL]
    connect!
  end

  # HTTP headers you need to send with every request.
  def headers
    {
      # Declare that you expect response in XML after a _successful_
      # response.
      "Accept"        => "application/xml",

      # Promise to send XML.
      "Content-Type"  => "application/xml; charset=utf-8",

      # All requests will be authenticated using HTTP Basic Auth, as
      # described in rfc2617. Your library probably has support for
      # basic_auth built in, I've passed the Authorization header
      # explicitly here only to show what happens at HTTP level.
      "Authorization" => "Basic #{auth_string}",

      # Tell Harvest a bit about your application.
      "User-Agent"    => USER_AGENT
    }
  end

  def auth_string
    Base64.encode64("#{ACCOUNT_EMAIL}:#{ACCOUNT_PASSWORD}").delete("\r\n")
  end

  def request path, method = :get, body = ""
    response = send_request( path, method, body)
    if response.class < Net::HTTPSuccess
      # response in the 2xx range
      on_completed_request
      return response
    elsif response.class == Net::HTTPServiceUnavailable
      # response status is 503, you have reached the API throttle
      # limit. Harvest will send the "Retry-After" header to indicate
      # the number of seconds your boot needs to be silent.
      raise "Got HTTP 503 three times in a row" if retry_counter > 3
      sleep(response['Retry-After'].to_i + 5)
      request(path, method, body)
    elsif response.class == Net::HTTPFound
      # response was a redirect, most likely due to protocol
      # mismatch. Retry again with a different protocol.
      @preferred_protocols.shift
      raise "Failed connection using http or https" if @preferred_protocols.empty?
      connect!
      request(path, method, body)
    else
      dump_headers = response.to_hash.map { |h,v| [h.upcase,v].join(': ') }.join("\n")
      raise "#{response.message} (#{response.code})\n\n#{dump_headers}\n\n#{response.body}\n"
    end
  end

  private

  def connect!
    port = has_ssl ? 443 : 80
    @connection             = Net::HTTP.new("#{@company}.harvestapp.com", port)
    @connection.use_ssl     = has_ssl
    @connection.verify_mode = OpenSSL::SSL::VERIFY_PEER if has_ssl
  end

  def has_ssl
    @preferred_protocols.first
  end

  def send_request path, method = :get, body = ''
    case method
    when :get
      @connection.get(path, headers)
    when :post
      @connection.post(path, body, headers)
    when :put
      @connection.put(path, body, headers)
    when :delete
      @connection.delete(path, headers)
    end
  end

  def on_completed_request
    @retry_counter = 0
  end

  def retry_counter
    @retry_counter ||= 0
    @retry_counter += 1
  end

end


########################################################################
#
# Demo the following:  - list all tasks
#                      - create a new task
#                      - read a specific task by id
#                      - update an existing task
#                      - delete task (commented out)
#


harvest = Harvest.new
puts "----------------------------"
puts "Reading all your tasks"
response = harvest.request '/tasks', :get
puts response.body



new_task_name = "ApiSample#{Time.now.to_i}"
puts "----------------------------"
puts "Creating a new task with name #{new_task_name}"
response = harvest.request '/tasks', :post, "<task> <name>#{new_task_name}</name> </task>"
new_task_location = response['Location']
new_task_id = new_task_location.gsub(/\/tasks\//, '')
puts "new task can be reached at #{new_task_location}"
puts "and  has the task_id of #{new_task_id}"


puts "----------------------------"
puts "Read a single task only (task_id=#{new_task_id})"
response = harvest.request new_task_location, :get
puts response.body

puts "----------------------------"
new_task_name = new_task_name + '-updated'
puts "Change name of task with id #{ new_task_id} to be #{new_task_name}"
harvest.request new_task_location, :put, "<task> <name>#{new_task_name}</name> </task>"


# puts "----------------------------"
# puts "Delete the new task (with id = #{new_task_id})"
# harvest.request new_task_location, :delete
