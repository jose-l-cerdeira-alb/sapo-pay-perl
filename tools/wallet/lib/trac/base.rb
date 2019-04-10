
require 'rubygems'
require 'mechanize'
require 'logger'
require "xmlrpc/client"
require 'yaml'
require 'uri'
require_relative '../configlib'

class TracBase

	def initialize(url,username,password)
		super()


		@uri = URI(url)
		@username = username
		@password = password

		@path = Dir.home()+"/.wallet/trac"


		@client = XMLRPC::Client.new(@uri.host, @uri.path, @uri.port)

		#log = Logger.new('log.txt')
		#log.level = Logger::INFO

		FileUtils.mkdir_p(@path) if !Dir.exists?(@path)
		
		@cookie_path = @path+"/cookies.yml"

		FileUtils.touch(@cookie_path) if !File.exists?(@cookie_path)

		@agent = Mechanize.new do|a|
			#a.log = log
			a.user_agent_alias = "Windows IE 6"
			a.cookie_jar.load @cookie_path, :format => :yaml
		end



		setcookies()

		

	end

	def teste()

		config = ConfigLib.new('teste.yml')


		doRequest(@agent);

	end

	def doLogin(agent)


		page = @agent.get(@uri.to_s)
	
		if !(/.*https:\/\/login\.intra\.sapo\.pt.*/.match(page.uri.to_s)) 
			return 
		end


		loginform = page.form_with(:id => "intra_login_form") 

		loginform.INTRA_LOGIN_USERNAME = @username
		loginform.INTRA_LOGIN_PASSWORD = @password

		agent.submit(loginform,loginform.buttons.first)

		agent.cookie_jar.save_as @cookie_path, :session => true, :format => :yaml

		setcookies()

	end

	def setcookies()
	
		url = @uri.to_s

		cookiestring = "";

		@agent.cookies.each do |cookie|
			if (cookie.valid_for_uri?(url))
				if (cookiestring.empty?)
					cookiestring = cookiestring + "" + cookie.cookie_value
				else

					cookiestring = cookiestring + ";" + cookie.cookie_value
				end
			end
		end


		

		@client.cookie = cookiestring



	end


	def get_current_user()
		

		page = @agent.get("http://#{@uri.host}:#{@uri.port}/sapo");

		result =  page.body().match /^.*logged in as ([\w\.\-]*) .*$/m

		if result.captures.size() > 0
			return result.captures[0] 
		end
		
		return nil

	end 


	def call(method,*args)

		
				begin

                   return param = @client.call(method,*args)
                
                rescue XMLRPC::FaultException => e

					return nil if /Ticket \d* does not exist./ =~ e.message

					raise e
			   
                rescue RuntimeError => e
                        
                        if (e.to_s() == "HTTP-Error: 302 Found")
							doLogin(@agent)

                        return param = @client.call(method,*args)
						end

					raise e
                end
	

	end

end
