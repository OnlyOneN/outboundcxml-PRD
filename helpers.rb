def getxmlattribute (document, xpath, attribute)
	# instance variables
	@doc = document
	@xpath = xpath
	@attribute = attribute

	if @doc.at_xpath(@xpath)
		if @doc.at_xpath(@xpath)[@attribute]
			if @doc.at_xpath(@xpath)[@attribute] != ''
				value = @doc.at_xpath(@xpath)[@attribute].strip
			else
				value = nil
			end
		else
			value = nil
		end
	else
		value = nil
	end

	return value
end

def getxmlvalue (xmlstring, xpath)
	#instance variables
	@xmlstring = xmlstring
	@xpath = xpath

	if @xmlstring.at_xpath(@xpath)
		if @xmlstring.at_xpath(@xpath).content.strip != ''
			value = @xmlstring.at_xpath(@xpath).content.strip
		else
			value = nil
		end
	else
		value = nil
	end

	return value
end

def getxmlrepeatingvalue (xmlstring, xpath, repeatingnode)
	#instance variablese
	@xmlstring = xmlstring
	@xpath = xpath
	@repeatingnode = repeatingnode

	if @xmlstring.xpath(@xpath + "/" + @repeatingnode)
		i = 0
		array = Array.new
		
		@xmlstring.xpath(@xpath + "//" + @repeatingnode).each do |node|
			if node.content.strip != ''
		   		array[i] = node.content.strip
			else
				array[i] = nil
			end
		   	i = i + 1
		end
	else
		array = []
	end

	return array
end

def createmssqlconn (host, user, password, dbname)
	#instance variables
	@user = user
	@password = password
	@host = host
	@dbname = dbname
	@timeout = 60

	conn = TinyTds::Client.new(:username => @user, :password => @password, :host => @host, :timeout => @timeout)

	return conn
end