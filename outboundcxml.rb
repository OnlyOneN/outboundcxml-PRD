require 'curb'
require 'nokogiri'
require 'tiny_tds'
require 'time'
require 'net/sftp'
require 'bigdecimal'
require 'json'

class Document
	def initialize strategy
		@document = strategy

		#load helper functions
		load "helpers.rb"

		#set environment 'dev', 'qa', or 'production'
		load "envconfig.rb"
	end

	def getrecords
		@document.getrecords
	end

	def createdoc
		@document.createdoc
	end

	def postdoc
		@document.postdoc
	end

	def sftpupload
		@document.sftpupload
	end

	def updaterecord
		@document.updaterecord
	end
end

class Invoice
	def getrecords
		# create connection to db
		@conn = createmssqlconn($ms_sql_host, $ms_sql_user, $ms_sql_password, $ms_sql_dbname)

		# get the invoice header data
		@result = @conn.execute("SELECT *
							FROM cxmlsync.dbo.invoices
							WHERE etl_status = 'processing'	
							ORDER BY id ASC")
	
		$invoices = Array.new
		@i = 0

		@result.each do |order|
			date = Time.now.strftime("%Y%m%d")
			datetime = Time.now.strftime("%FT%T%:z")
			if order['invoice_date'].nil? || order['invoice_date'].empty?
				invoiceDate = ''
			else
				invoiceDate = Time.parse(order['invoice_date'].to_s[0,10]).strftime("%FT%T%:z")
			end

			if order['shipping_date'].nil? || order['shipping_date'].empty?
				shippingDate = ''
			else
				shippingDate = Time.parse(order['shipping_date'].to_s[0,10]).strftime("%FT%T%:z")
			end
			id = order['id']
			referenceId = order['reference_id']
			payloadId = date + "." + id.to_s + "." + rand.to_s + "@neb.com"
			shipToAddressId = order['external_shipto_id']
			orderSenderIdentity = order['sender_id']
			orderFromIdentity = order['from_id']
			
			if (referenceId.nil? && referenceId != '') || (orderSenderIdentity == 'FVTECH')
				case $environment
				when 'production'
					case order['sap_soldto_id'].to_s
					# when '0001000851'	# Stanford University
					# 	orderSenderIdentity = 'SciQuest'
					# 	orderFromIdentity = 'STANFORD'
					# when '0001000852'	# Stanford University Hospital
					# 	orderSenderIdentity = 'SciQuest'
					# 	orderFromIdentity = 'STANFORD'
					# when '0001004009'	# Stanford University Bio Sciences Storeroom
					# 	orderSenderIdentity = 'SciQuest'
					# 	orderFromIdentity = 'STANFORD'
					when '0001000929'	# University of California San Fran
						orderSenderIdentity = 'SciQuest'
						orderFromIdentity = 'UCSF'
					when '0001003974'	# University of California San Fran Freezer
						orderSenderIdentity = 'SciQuest'
						orderFromIdentity = 'UCSF'
					when '0001000925'	# University of California Irvine
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'
					when '0001001506'	# University of California Irvine Medical Center
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'
					when '0001004072'	# University of California Irvine Freezer
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'
					else

					end
				else
					case order['sap_soldto_id'].to_s
					when '0001000851'	# Stanford University
					  	orderSenderIdentity = 'SciQuest'
					 	orderFromIdentity = 'STANFORD-T'
					when '0001000852'	# Stanford University Hospital
					 	orderSenderIdentity = 'SciQuest'
					 	orderFromIdentity = 'STANFORD-T'
					when '0001004009'	# Stanford University Bio Sciences Storeroom
					 	orderSenderIdentity = 'SciQuest'
					 	orderFromIdentity = 'STANFORD-T'
					when '0001000929'	# University of California San Fran
						orderSenderIdentity = 'SciQuest'
						orderFromIdentity = 'UCSF-T'
					when '0001003974'	# University of California San Fran Freezer
						orderSenderIdentity = 'SciQuest'
						orderFromIdentity = 'UCSF-T'
					when '0001000925'	# University of California Irvine
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'	
					when '0001001506'	# University of California Irvine Medical Center
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'
					when '0001004072'	# University of California Irvine Freezer
						orderSenderIdentity = 'UCIrvine'
						orderFromIdentity = 'UCI'	
					else

					end
				end
			end

			toIdentity = orderFromIdentity
					
			case orderSenderIdentity.to_s
			when 'SciQuest'
				network = 'sciquest'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			when 'BROAD'
				network = 'sciquest'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			when 'sysadmin@ariba.com'
				network = 'ariba'
			 	fromDomain = 'NetworkID'
			 	toDomain = 'NetworkID'
			 	senderDomain = 'NetworkID'

				case $environment
				when 'production'			
			 		fromIdentity = 'AN01000000505'
					senderIdentity = 'AN01000000505'
			 		senderSharedSecret = 'ariba123'
			 	else
			 		fromIdentity = 'AN01000000505-T'
					senderIdentity = 'AN01000000505-T'
			 		senderSharedSecret = 'NebAriba1234'	
			 	end
			when 'UCIrvine'
				network = 'sftp'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkId'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			 	senderSharedSecret = ''
			when '078366142'
				network = 'buyerquest'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'DUNS'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			 	senderSharedSecret = 'NEBBuyerQuest'
			else

			end
				
			case orderFromIdentity.to_s
			when '1425594' #MIT/Lincoln Labs
			 	network = 'bottomline'
			 	fromDomain = 'DUNS'
				fromIdentity = ''
			 	toDomain = 'DUNS'
				toIdentity = ''
				senderDomain = 'DUNS'
			 	senderIdentity = 'cxml_autouser_neb'

				case $environment
				when 'production'
					senderSharedSecret = 'P@ssw0rd*'	
			 		#senderSharedSecret = 'n!m4vu#9'
			 	else
			 		senderSharedSecret = 'y#cxn4!h'	
			 	end
			when /SCRIPPS/ #Scripps
				senderSharedSecret = 'NebScripps'
			when /YESHIVA/ #YeshivaU			
				senderSharedSecret = 'NebYeshiva'
			when /STANFORD/ #SciQuest/Stanford University
				senderSharedSecret = 'NebStanford'
			when '623544785' #Broad
			 	toDomain = 'DUNS'
				senderSharedSecret = 'NebBroad'
			when /UCSC/ #UCSantaCruz
			 	senderSharedSecret = 'NebUCSC'
			when /WEIL/ #Weill Medical College
			 	senderSharedSecret = 'NebWeill'
			when /UCB/ #UCBerkeley
			 	senderSharedSecret = 'NebUCBerkeley'
			when /WASHINGTONU/ #WashingtonU
			 	senderSharedSecret = 'NebWashU'
			when /UCSF/ #UCSanFrancisco
			 	senderSharedSecret = 'NebUcsf'
			when /HARVARD/ #HarvardU
			 	senderSharedSecret = 'NebHarvard'
			when /VATECH/ #VirginiaTech
			 	senderSharedSecret = 'NebVATech'
			when /UCSD/ #UCSanDiego
			 	senderSharedSecret = 'NebUcsd'
			when /FREDHUTCH/#FredHutchinsonCancerReasearchCenter
			 	senderSharedSecret = 'NebFredHutch'
			when /UCOLORADO/ #UColorado
			 	senderSharedSecret = 'NebUCOLORADO'
			when /UVIRGINIA/ #UVirginia
			 	senderSharedSecret = 'NebUVirginia'
			when /UTSWMC/ #UTSWMedicalCenter
			 	senderSharedSecret = 'NebUTSWMC'
			when /UMASS/ #UMass
			 	senderSharedSecret = 'NebUMass'
			when /UMINNESOTA/ #UMinnesota
			 	senderSharedSecret = 'NebUMinnesota'
			when /NORTHWESTERN/ #NorthwesternU
			 	senderSharedSecret = 'NebNorthwestern'
			when /TEXASTECH/ #TexasTech
				senderSharedSecret = 'NebTexasTech'
			when /UPITTSBURG/ #UPittsburgh
			 	senderSharedSecret = 'NebUPittsburg'
			when /PRINCETON/ #PrincetonU
			 	senderSharedSecret = 'NebPrinceton'
			when /DARTMOUTH/ #Dartmouth College
			 	senderSharedSecret = 'NebDartmouth'
			when /EINSTEIN/ #Einstein Medical
				senderSharedSecret = 'NEBEinstein'
			when /CORNELL/ #Cornell University
				network = 'sftp'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			 	senderSharedSecret = 'NebCornell'
			when /SALK/ #Salk Institute
				senderSharedSecret = 'NEBSalk'
			when '009214214' #BuyerQuest/Stanford University
				case $environment
				when 'production'
					$invoicepath = 'stanfordexpress'
				else
					$invoicepath = 'stanford'
				end
			when /NEBRASKA/ #Univ of Nebraska
				senderSharedSecret = 'NEBNEB'
			when /DUKE/ #Duke University
				senderSharedSecret = 'NEBDuke'
			when /AN01014477293/ #Illumina
				case $environment
				when 'production'
					fromIdentity = 'AN01026151554'
					senderIdentity = 'AN01026151554'
				else
					fromIdentity = 'AN01026151554-T'
					senderIdentity = 'AN01026151554-T'
				end
			when /NYU/ #New York University
				senderSharedSecret = 'NEBNYU'
			else

			end

			@hash = Hash[
						"id", id,
						"payload_id", payloadId,
						"datetime", datetime,
						"network", network,
						"from_domain", fromDomain,
						"from_identity", fromIdentity,
						"to_domain", toDomain,
						"to_identity", toIdentity,
						"sender_domain", senderDomain,
						"sender_identity", senderIdentity,
						"sender_shared_secret", senderSharedSecret,
						"user_agent", 'ruby/nokogiri',
						"account_number", order['sap_soldto_id'] + '_' + order['sap_shipto_id'],
						"invoice_date", invoiceDate,
						"invoice_id", order['invoice_id'],
						"order_id", order['customer_po'],
						"reference_id", order['reference_id'],
						"external_shipto_id", order['external_shipto_id'],
						"shipto_name", order['shipto_name'],
						"shipto_line1", order['shipto_name2'],
						"shipto_line2", order['shipto_name3'],
						"shipto_line3", order['shipto_name4'],
						"shipto_line4", order['shipto_street'],
						"shipto_city", order['shipto_city'],
						"shipto_state", order['shipto_state'],
						"shipto_postal_code", order['shipto_postal_code'],
						"external_billto_id", order['external_billto_id'],
						"billto_name", order['billto_name'],
						"billto_line1", order['billto_name2'],
						"billto_line2", order['billto_name3'],
						"billto_line3", order['billto_name4'],
						"billto_line4", order['billto_street'],
						"billto_city", order['billto_city'],
						"billto_state", order['billto_state'],
						"billto_postal_code", order['billto_postal_code'],
						"invoice_amount", order['net_value'],
						"shipping_amount", order['freight_amount'],
						"shipping_date", shippingDate
					]

			$invoices[@i] = @hash
					
			@i = @i + 1
		end

		$j = 0
		$invoices.each do 
		 	@result2 = @conn.execute("SELECT *
		 						FROM cxmlsync.dbo.invoice_items
		 						WHERE invoice_id = '#{$invoices[$j]['invoice_id']}'
								ORDER BY line_item_id ASC")

		 	$detailLines = Array.new
			@i = 0
		 	@result2.each do |line|
		 		@hash = Hash[
						"product_id", line['product_id'],
						"quantity", line['quantity'],
						"item_price", line['item_price'],
						"item_gross", line['item_gross'],
						"item_tax", line['item_tax'],
						"customer_line_number", line['customer_line_number'],
						"description", line['description'],
						"customer_line_id", line['customer_line_id']
					]

				$detailLines[@i] = @hash
		
		 		@i = @i + 1
		 	end

		 	unless $detailLines.nil? || $detailLines.empty?
            	self.createdoc
            end
            $j = $j + 1

		end

		@conn.close
	end

	def createdoc
		$invalid = false
		$error = ''
		$datetime = Time.now.strftime("%FT%T%:z")
		
		case  $invoices[$j]['network'] #network
		when 'ariba' #Ariba supplier network
			case $invoices[$j]['to_identity'] #toIdentity
			when /AN01000219104/ #Medimmune/AstraZeneca specific
				load "./maps/invoice/medimmune_astrazeneca_inv.rb"
			when /AN01006719155/
				load "./maps/invoice/medimmune_astrazeneca_inv.rb"
			when /AN01011077349/ #Purdue University specific
				load "./maps/invoice/purdue_university_inv.rb"
			when /AN01005361409/ #HHMI specific
				load "./maps/invoice/hhmi_inv.rb"
			when /AN01014477293/ #Illumina specific
				load "./maps/invoice/illumina_inv.rb"			
			else #most ariba invoices will use this
				load "./maps/invoice/ariba_default_inv.rb" 
			end
		when 'sciquest' #SciQuest supplier network
			load "./maps/invoice/sciquest_default_inv.rb" 
		when 'bottomline' #Bottomline exhange
			load "./maps/invoice/mit_lincolnlabs_inv.rb" #MIT and Lincoln Labs specific
		when 'buyerquest' #BuyerQuest supplier network
			load "./maps/invoice/buyerquest_default_inv.rb"
		when 'sftp' #NEB sftp
			case $invoices[$j]['to_identity'] #toIdentity
			when /UCI/ #University of California Irvine specific
				load "./maps/invoice/uc_irvine_inv.rb"
			when /CORNELL/ #Cornell University specific
				load "./maps/invoice/cornell_inv.rb"
			else
				$error = 'not a valid identity'
				$invalid = true
				puts $error
			end
		else
			$error = 'not a valid network'
			$invalid = true
			puts $error
		end

		if $invoices[$j]['network'] != 'sftp'
			self.postdoc
		else
			self.sftpupload
		end

		self.updaterecord
	end

	def postdoc
		if $invalid != true
			case $environment
			when 'qa'		
				case $invoices[$j]['network']
				when 'ariba'
					url = 'https://service.ariba.com/service/transaction/cxml.asp'
				when 'sciquest'
					url = 'https://usertest.sciquest.com/apps/Router/CXMLInvoiceImport'	
				when 'bottomline'
					url = 'https://uat.bottomlinexchange.com/service/upload/cxml'
				when 'buyerquest'
					url = 'https://uat.buyerquest.net/' + $invoicepath + '/cxmlgate/abc/invoice'
				else

				end		
			when 'production'		
				case $invoices[$j]['network']
				when 'ariba'
					url = 'https://service.ariba.com/service/transaction/cxml.asp'
				when 'sciquest'
					url = 'https://solutions.sciquest.com/apps/Router/CXMLInvoiceImport'		
				when 'bottomline'
					url = 'https://www.bottomlinexchange.com/service/upload/cxml'
				when 'buyerquest'
					url = 'https://www.buyerquest.net/' + $invoicepath + '/cxmlgate/abc/invoice'
				else

				end
				
			else

			end

			#post the xml
			c = Curl::Easy.http_post(url, $xml) do |curl|
				curl.timeout = 0
				curl.ssl_verify_peer = true
				curl.headers['Accept'] = 'application/xml'
				curl.headers["Content-type"] = 'application/xml'

				curl.on_complete {
					$response = @conn.escape(curl.body_str)

					puts $response
	
					if responseDoc = Nokogiri::XML.parse($response)
						$xmlResponsePayloadId = getxmlattribute(responseDoc, 'cXML','payloadID')
						$xmlResposneTimestamp = getxmlattribute(responseDoc, 'cXML', 'timestamp')
						$xmlResponseCode = getxmlattribute(responseDoc, 'cXML/Response/Status', 'code')
						$xmlResponseText = getxmlattribute(responseDoc, 'cXML/Response/Status', 'text')
						$xmlResponseMessage = getxmlvalue(responseDoc, 'cXML/Response/Status')
					end			
				}	
			end
		end
	end

	def sftpupload
		case $environment
		when 'qa'
			case $invoices[$j]['network'] #network
			when 'sftp' #NEB sftp
				case $invoices[$j]['to_identity'] #toIdentity
				when /UCI/ #University of California Irvine specific
					#change this directory path as needed
					Dir.glob("#{$workingdir}/sftp/ucirvine" + '/*.xml') do |fname|
						# upload the file/
				 		Net::SFTP.start($sftphost, $sftpuser, :password => $sftppass, :port => $sftpport) do |sftp|
				 			sftp.upload!(fname, "#{$sftpuser}/test/invoices/" + File.basename(fname))
						end

						File.delete(fname)
					end
				when /CORNELL/ #Cornell University specific
					#change this directory path as needed
					Dir.glob("#{$workingdir}/sftp/cornell" + '/*.xml') do |fname|
						# upload the file/
				 		Net::SFTP.start($sftphost3, $sftpuser3, :port => $sftpport3) do |sftp|
				 			sftp.upload!(fname, File.basename(fname))
						end

						File.delete(fname)
					end
				else
					
				end
			else
			
			end
		when 'production'
			case $invoices[$j]['network'] #network
			when 'sftp' #NEB sftp
				case $invoices[$j]['to_identity'] #toIdentity
				when /UCI/ #University of California Irvine specific
					#change this directory path as needed
					Dir.glob("#{$workingdir}/sftp/ucirvine" + '/*.xml') do |fname|
						# upload the file/
				 		Net::SFTP.start($sftphost, $sftpuser, :password => $sftppass, :port => $sftpport) do |sftp|
				 			sftp.upload!(fname, "#{$sftpuser}/production/invoices/" + File.basename(fname))
						end

						File.delete(fname)
					end
				when /CORNELL/ #Cornell University specific
					#TODO: sftp upload using public/private key auth
				else
					
				end
			else
			
			end		
		else

		end
	end

	def updaterecord
		$xml = @conn.escape("#{$xml}")
		case $invalid
		when true	
			client = @conn.execute("UPDATE cxmlsync.dbo.invoices
								SET etl_status = 'error',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$error}'
								WHERE id = '#{$invoices[$j]['id']}'")
			client.do
		else	
		 	if $invoices[$j]['network'] != 'sftp'
				case $xmlResponseCode[0]
				when '2'
					client = @conn.execute("UPDATE cxmlsync.dbo.invoices
								SET etl_status = 'transferred',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}',
						 			response = '#{$response}',
						 			response_code = '#{$xmlResponseCode}',
						 			response_text = '#{$xmlResponseText}',
						 			response_message = '#{$xmlResponseMessage}'
								WHERE id = '#{$invoices[$j]['id']}'")
					client.do
				else
					client = @conn.execute("UPDATE cxmlsync.dbo.invoices
								SET etl_status = 'error',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}',
						 			response = '#{$response}',
						 			response_code = '#{$xmlResponseCode}',
						 			response_text = '#{$xmlResponseText}',
						 			response_message = '#{$xmlResponseMessage}'
								WHERE id = '#{$invoices[$j]['id']}'")
					client.do
				end
			else
				client = @conn.execute("UPDATE cxmlsync.dbo.invoices
								SET etl_status = 'file_generated',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}'
								WHERE id = '#{$invoices[$j]['id']}'")
				client.do
			end
		end
	end
end

class Confirmation
	def getrecords
		# create connection to db
		@conn = createmssqlconn($ms_sql_host, $ms_sql_user, $ms_sql_password, $ms_sql_dbname)

		# get the confirmation header data
		@result = @conn.execute("SELECT *
							FROM cxmlsync.dbo.confirmations
							WHERE etl_status = 'processing'	
							ORDER BY id ASC")

	 	$confirmations = Array.new
	 	@i = 0

	 	@result.each do |order|
			date = Time.now.strftime("%Y%m%d")
			datetime = Time.now.strftime("%FT%T%:z")
	 		if order['customer_po_date'].nil? || order['customer_po_date'].empty?
				orderDate = ''
			else
				orderDate = Time.parse(order['customer_po_date'].to_s).strftime("%FT%T%:z")
	 		end
			id = order['id']
	 		payloadId = date + "." + id.to_s + "." + rand.to_s + "@neb.com"
	 		orderSenderIdentity = order['sender_id']
			orderFromIdentity = order['from_id']
			toIdentity = orderFromIdentity
			case orderSenderIdentity.to_s
			when 'SciQuest'
				network = 'sciquest'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			when 'sysadmin@ariba.com'
				network = 'ariba'
			 	fromDomain = 'NetworkID'
			 	toDomain = 'NetworkID'
			 	senderDomain = 'NetworkID'

				case $environment
				when 'production'			
			 		fromIdentity = 'AN01000000505'
					senderIdentity = 'AN01000000505'
			 		senderSharedSecret = 'ariba123'
			 	else
			 		fromIdentity = 'AN01000000505-T'
					senderIdentity = 'AN01000000505-T'
			 		senderSharedSecret = 'NebAriba1234'	
			 	end
			when 'FVTECH'
				network = 'emdeon'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
				toIdentity = 'EMDEON'
			 	senderDomain = 'DUNS'
			 	senderIdentity = '066605403'
			 	senderSharedSecret = ''

			else

			end

			case orderFromIdentity.to_s
			when /SCRIPPS/ #Scripps
				senderSharedSecret = 'NebScripps'
			when /UCHICAGO/ #YeshivaU			
				senderSharedSecret = 'UCHICAGO'
			else

			end

	 		@hash = Hash[
						"id", id,
						"payload_id", payloadId,
						"datetime", datetime,
						"network", network,
						"from_domain", fromDomain,
						"from_identity", fromIdentity,
						"to_domain", toDomain,
						"to_identity", toIdentity,
						"sender_domain", senderDomain,
						"sender_identity", senderIdentity,
						"sender_shared_secret", senderSharedSecret,
						"user_agent", 'ruby/nokogiri',
						"confirmation_id", order['order_id'],
						"order_date", orderDate,
						"order_id", order['customer_po'],
						"reference_id", order['reference_id'],
						"soldto_id", order['sold_to_id'],
						"shipto_id", order['ship_to_id'],
						'shipping_amount', order['freight_amount'], 
						"shipto_name", order['shipto_name'],
						"shipto_line1", order['shipto_line1'],
						"shipto_line2", order['shipto_line2'],
						"shipto_line3", order['shipto_line3'],
						"shipto_line4", order['shipto_line4'],
						"shipto_city", order['shipto_city'],
						"shipto_state", order['shipto_state'],
						"shipto_postal_code", order['shipto_zip'],
						"shipto_country", order['shipto_country']
					]

			$confirmations[@i] = @hash					
							
	 		@i = @i + 1		
	 	end

	 	$j = 0
		$confirmations.each do 
		  	@result2 = @conn.execute("SELECT *
		  						FROM cxmlsync.dbo.confirmation_items
		  						WHERE order_id = '#{$confirmations[$j]['confirmation_id']}'
			 					ORDER BY line_item_id ASC")

		  	$detailLines = Array.new
			@i = 0
		  	@result2.each do |line|
				if line['shipping_date'].nil? || line['shipping_date'].empty?
					lineShippingDate = ''
				else
					lineShippingDate = Time.parse(line['shipping_date'].to_s[0,10]).strftime("%FT%T%:z")
				end
				@hash = Hash[
						"product_id", line['product_id'],
						"description", line['description'],
						"ordered_quantity", line['ordered_quantity'],
						"confirmed_quantity", line['confirmed_quantity'],
						"customer_line_id", line['customer_line_id'],
						"customer_line_number", line['customer_line_number'],
						"unit_of_measure", line['unit_of_measure'],
						"net_price", line['net_price'],
						"net_value", line['net_value'],
						"currency", line['currency'],
						"tax_amount", line['tax_amount'],
						"shipping_date", lineShippingDate
					]

				$detailLines[@i] = @hash
		
		  		@i = @i + 1
		 	end

		  	unless $detailLines.nil? || $detailLines.empty?
            	self.createdoc
          	end
            $j = $j + 1

		end

		@conn.close		
	end

	def createdoc
		$invalid = false
		$error = ''
		$datetime = Time.now.strftime("%FT%T%:z")

		case $confirmations[$j]['network'] #network
		when 'ariba'
			load "./maps/confirmation/ariba_default_confirm.rb"
		when 'sciquest'
			load "./maps/confirmation/sciquest_default_confirm.rb"
		when 'emdeon'
			load "./maps/confirmation/emdeon_default_confirm.rb"
		else
			$error = 'not a valid network'
			$invalid = true
			puts $error
		end

		if $confirmations[$j]['network'] != 'emdeon'
			self.postdoc
		else
			self.sftpupload
		end

		self.updaterecord
	end

	def postdoc
		if $invalid != true
			case $environment
			when 'qa'
				case $confirmations[$j]['network']
				when 'ariba'
					url = 'https://service.ariba.com/service/transaction/cxml.asp'
				when 'sciquest'
					url = 'https://usertest.sciquest.com/apps/Router/CXMLReceive'
				else

				end	
			when 'production'
				case $confirmations[$j]['network']
				when 'ariba'
					url = 'https://service.ariba.com/service/transaction/cxml.asp'
				when 'sciquest'
					url = 'https://solutions.sciquest.com/apps/Router/CXMLReceive'
				else

				end	
			else

			end

			#post the xml
			c = Curl::Easy.http_post(url, $xml) do |curl|
				curl.timeout = 0
				curl.ssl_verify_peer = true
				curl.headers['Accept'] = 'application/xml'
				curl.headers["Content-type"] = 'application/xml'

				curl.on_complete {
					$response = @conn.escape(curl.body_str)

					puts $response

					if responseDoc = Nokogiri::XML.parse($response)
						$xmlResponsePayloadId = getxmlattribute(responseDoc, 'cXML','payloadID')
						$xmlResposneTimestamp = getxmlattribute(responseDoc, 'cXML', 'timestamp')
						$xmlResponseCode = getxmlattribute(responseDoc, 'cXML/Response/Status', 'code')
						$xmlResponseText = getxmlattribute(responseDoc, 'cXML/Response/Status', 'text')
						$xmlResponseMessage = getxmlvalue(responseDoc, 'cXML/Response/Status')
					end						
				}	
			end
		end
	end

	def sftpupload
		case $environment
		when 'qa'	
			case $confirmations[$j]['network'] #network
			when 'emdeon'
				#change this directory path as needed
				Dir.glob("#{$workingdir}/sftp/emdeon" + '/*.xml') do |fname|
					# upload the file/
				 	Net::SFTP.start($sftphost2, $sftpuser2, :password => $sftppass2, :port => $sftpport2) do |sftp|
				 		sftp.upload!(fname, "/in/Confirmations/test/" + File.basename(fname))
					end

					File.delete(fname)
				end
			else

			end
		when 'production'
			case $confirmations[$j]['network'] #network
			when 'emdeon'
				#change this directory path as needed
				Dir.glob("#{$workingdir}/sftp/emdeon" + '/*.xml') do |fname|
					# upload the file/
				 	Net::SFTP.start($sftphost2, $sftpuser2, :password => $sftppass2, :port => $sftpport2) do |sftp|
				 		sftp.upload!(fname, "/neb/In/Confirmations/" + File.basename(fname))
				 		#sftp.upload!(fname, "/in/Confirmations/" + File.basename(fname))
					end

					File.delete(fname)
				end
			else

			end
		else

		end
	end

	def updaterecord
		$xml = @conn.escape("#{$xml}")
		case $invalid
		when true
			client = @conn.execute("UPDATE cxmlsync.dbo.confirmations
								SET etl_status = 'error',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$error}'
								WHERE id = '#{$confirmations[$j]['id']}'")
			client.do		
		else	
			if $confirmations[$j]['network'] != 'emdeon'
				case $xmlResponseCode[0]
				when '2'
					client = @conn.execute("UPDATE cxmlsync.dbo.confirmations
									SET etl_status = 'transferred',
										etl_timestamp = '#{Time.now.strftime("%F %T")}',
							 			request = '#{$xml}',
							 			response = '#{$response}',
							 			response_code = '#{$xmlResponseCode}',
							 			response_text = '#{$xmlResponseText}',
							 			response_message = '#{$xmlResponseMessage}'
									WHERE id = '#{$confirmations[$j]['id']}'")
					client.do
				else
					client = @conn.execute("UPDATE cxmlsync.dbo.confirmations
									SET etl_status = 'error',
										etl_timestamp = '#{Time.now.strftime("%F %T")}',
							 			request = '#{$xml}',
							 			response = '#{$response}',
							 			response_code = '#{$xmlResponseCode}',
							 			response_text = '#{$xmlResponseText}',
							 			response_message = '#{$xmlResponseMessage}'
									WHERE id = '#{$confirmations[$j]['id']}'")
					client.do
				end
			else
				client = @conn.execute("UPDATE cxmlsync.dbo.confirmations
								SET etl_status = 'file_generated',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}'
								WHERE id = '#{$confirmations[$j]['id']}'")
				client.do
			end	
		end
	end
end

class Shipnotice
	def getrecords
		# create connection to db
		@conn = createmssqlconn($ms_sql_host, $ms_sql_user, $ms_sql_password, $ms_sql_dbname)

		# get the shipnotice header data
		@result = @conn.execute("SELECT *
							FROM cxmlsync.dbo.shipnotices
							WHERE etl_status = 'processing'	
							ORDER BY id ASC")

		$shipnotices = Array.new
		@i = 0

		@result.each do |order|
			id = order['id']
			date = Time.now.strftime("%Y%m%d")
			datetime = Time.now.strftime("%FT%T%:z")
			if order['delivery_date'].nil? || order['delivery_date'].empty?
				deliveryDate = ''
				shippingDate = ''
			else
				deliveryDate = Time.parse(order['delivery_date'].to_s[0,10]).strftime("%FT%T%:z")
				shippingDate = Time.parse(order['delivery_date'].to_s[0,10]).strftime("%FT%T%:z")
			end

			if order['po_date'].nil? || order['po_date'].empty?
				poDate = ''
			else
				poDate = Time.parse(order['po_date'].to_s).strftime("%FT%T%:z")
			end

			payloadId = date + "." + id.to_s + "." + rand.to_s + "@neb.com"

			# logic to handle variances in data usage for initial stock orders from SAP
			if order['customer_po'] == 'NEBnow Initial Inven'
				orderSenderIdentity = 'SFDC'
				orderFromIdentity = 'FREEZERPROG'
				referenceId = order['order_id']
			else
				orderSenderIdentity = order['sender_id']
				orderFromIdentity = order['from_id']
				referenceId = order['reference_id']
			end
		
			case orderSenderIdentity.to_s
			when 'SFDC'
				network = 'sfdc'
				fromDomain = 'DUNS'
	 			fromIdentity = '066605403'
				toDomain = 'NetworkID'			
				senderDomain = 'DUNS'
				senderIdentity = '066605403'
	 			senderSharedSecret = 'NEBTURNKEY'
			
				case $environment
				when 'production'			
			 		toIdentity = 'FREEZERPROG'
			 	else
			 		toIdentity = 'FREEZERPROG-T'
			 	end
			else

			end

			case order['sap_soldto_id']
			when '0001003271' # NEB UK orders
				network = 'neb-uk'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
				toIdentity = 'NEBUK-ASN-XMLID'
				senderDomain = 'DUNS'
				senderIdentity = '066605403'
	 			senderSharedSecret = 'NEBUKPROD-SENDER'
			when '0001000008' # NEB UK orders
				network = 'neb-uk'
				fromDomain = 'DUNS'
				fromIdentity = '066605403'
				toDomain = 'NetworkID'
				toIdentity = 'NEBUK-ASN-XMLID'
				senderDomain = 'DUNS'
				senderIdentity = '066605403'
				senderSharedSecret = 'NEBUKPROD-SENDER'
			else

			end



			@hash = Hash[
						"id", id,
						"payload_id", payloadId,
						"datetime", datetime,
						"network", network,
						"from_domain", fromDomain,
						"from_identity", fromIdentity,
						"to_domain", toDomain,
						"to_identity", toIdentity,
						"sender_domain", senderDomain,
						"sender_identity", senderIdentity,
						"sender_shared_secret", senderSharedSecret,
						"user_agent", 'ruby/nokogiri',
						"account_number", order['sap_soldto_id'] + '_' + order['sap_shipto_id'],
						"order_id", order['customer_po'],
						"reference_id", referenceId,
						'delivery_date' ,deliveryDate, 
						"shipping_date", shippingDate,
						"po_date", poDate,
						"carrier", order['carrier'],
						"tracking_number", order['tracking_number'],
						"order_number", order['order_id'],
						"delivery_id", order['delivery_id']
					]

			$shipnotices[@i] = @hash
						
			@i = @i + 1
		end

		$j = 0
		$shipnotices.each do 
		 	@result2 = @conn.execute("SELECT *
		 						FROM cxmlsync.dbo.shipnotice_items
		 						WHERE delivery_id = '#{$shipnotices[$j]['delivery_id']}'
		 						AND order_id = '#{$shipnotices[$j]['order_number']}'
								ORDER BY line_item_id ASC")

		 	$detailLines = Array.new
			@i = 0
		 	@result2.each do |line|
		 		@hash = Hash[
						"product_id", line['product_id'],
						"description", line['description'],
						"quantity", line['quantity'],
						"customer_line_id", line['customer_line_id'],
						"customer_line_number", line['customer_line_number']
					]

				$detailLines[@i] = @hash	
	
		 		@i = @i + 1
		 	end

		 	unless $detailLines.nil? || $detailLines.empty?
            	self.createdoc
            end
            $j = $j + 1

		end

		@conn.close
	end

	def createdoc
		$invalid = false
		$error = ''
		$datetime = Time.now.strftime("%FT%T%:z")

		case $shipnotices[$j]['network'] #network
		when 'sfdc'
			case $shipnotices[$j]['to_identity'] #toIdentity
			when /FREEZERPROG/ #NEBnow freezers
				load "./maps/shipnotice/nebnow_asn.rb"
			else
				$error = 'not a valid identity'
				$invalid = true
				puts $error
			end
		when 'neb-uk'
			load "./maps/shipnotice/nebuk_asn.rb"
		else
			$error = 'not a valid network'
			$invalid = true
			puts $error
		end

		self.postdoc
		self.updaterecord
	end

	def postdoc
		if $invalid != true
			case $environment
			when 'qa'
			 	case $shipnotices[$j]['network']
			 	when 'sfdc'
			 		url = 'https://apiqa.neb.com/purchaseorder/sendasn'
			 	when 'neb-uk'
			 		url = 'http://192.168.235.20/xmllistener.php' # internal address
			 		# url = https://post.uk.neb.com/xmllistener.php # external address (needs firewall rules added on UK's end)
			 	else

			 	end	
			when 'production'
				case $shipnotices[$j]['network']
			 	when 'sfdc'		
			 		url = 'https://api.neb.com/purchaseorder/sendasn'
			 	when 'neb-uk'
			 		url = 'http://192.168.235.20/xmllistener.php' # internal address
			 		# url = https://post.uk.neb.com/xmllistener.php # external address (needs firewall rules added on UK's end)
			 	else

			 	end	
			else

			end

			#post the xml
			c = Curl::Easy.http_post(url, $xml) do |curl|
				curl.timeout = 0
				curl.ssl_verify_peer = true
				curl.headers['Accept'] = 'application/xml'
				curl.headers["Content-type"] = 'application/xml'

				curl.on_complete {
					$response = @conn.escape(curl.body_str)

					puts $response

					case $shipnotices[$j]['network']
			 		when 'sfdc'		
						if jsonResponse = JSON.parse($response)
							$jsonResponseMessage = jsonResponse["Message"]
							$jsonResponseCode = jsonResponse["StatusCode"]
							$jsonResponseOpportunityId = jsonResponse["OpportunityId"]
							$jsonResponseDescription = jsonResponse["Description"]
						end
					else
						if responseDoc = Nokogiri::XML.parse($response)
							$xmlResponsePayloadId = getxmlattribute(responseDoc, 'cXML','payloadID')
							$xmlResposneTimestamp = getxmlattribute(responseDoc, 'cXML', 'timestamp')
							$xmlResponseCode = getxmlattribute(responseDoc, 'cXML/Response/Status', 'code')
							$xmlResponseText = getxmlattribute(responseDoc, 'cXML/Response/Status', 'text')
							$xmlResponseMessage = getxmlvalue(responseDoc, 'cXML/Response/Status')
						end
					end
				}	
			end
		end
	end

	def updaterecord
		$xml = @conn.escape("#{$xml}")
		case $invalid
		when true	
			client = @conn.execute("UPDATE cxmlsync.dbo.shipnotices
								SET etl_status = 'error',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$error}'
								WHERE id = '#{$shipnotices[$j]['id']}'")
			client.do
		else
			if (defined?($jsonResponseCode)).nil?
			 	case $xmlResponseCode[0]
				when '2'
					client = @conn.execute("UPDATE cxmlsync.dbo.shipnotices
									SET etl_status = 'transferred',
										etl_timestamp = '#{Time.now.strftime("%F %T")}',
								 		request = '#{$xml}',
								 		response = '#{$response}',
								 		response_code = '#{$xmlResponseCode}',
								 		response_text = '#{$xmlResponseText}',
								 		response_message = '#{$xmlResponseMessage}'
									WHERE id = '#{$shipnotices[$j]['id']}'")
					client.do
				else
					client = @conn.execute("UPDATE cxmlsync.dbo.shipnotices
									SET etl_status = 'error',
										etl_timestamp = '#{Time.now.strftime("%F %T")}',
								 		request = '#{$xml}',
								 		response = '#{$response}',
								 		response_code = '#{$xmlResponseCode}',
								 		response_text = '#{$xmlResponseText}',
								 		response_message = '#{$xmlResponseMessage}'
									WHERE id = '#{$shipnotices[$j]['id']}'")
					client.do
				end	
			else
		 		case $jsonResponseCode[0]
		 		when '2'
					client = @conn.execute("UPDATE cxmlsync.dbo.shipnotices
								SET etl_status = 'transferred',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}',
						 			response = '#{$response}',
						 			response_code = '#{$jsonResponseCode}',
						 			response_text = '#{$jsonResponseOpportunityId}',
						 			response_message = '#{$xmlResponseMessage}'
								WHERE id = '#{$shipnotices[$j]['id']}'")
					client.do
			 	else
					client = @conn.execute("UPDATE cxmlsync.dbo.shipnotices
								SET etl_status = 'error',
									etl_timestamp = '#{Time.now.strftime("%F %T")}',
						 			request = '#{$xml}',
						 			response = '#{$response}',
						 			response_code = '#{$jsonResponseCode}',
						 			response_text = '#{$jsonResponseDescription}',
						 			response_message = '#{$jsonResponseMessage}'
								WHERE id = '#{$shipnotices[$j]['id']}'")

					client.do
			 	end		
			end
		end
	end
end

#create and send invoices
Document.new(Invoice.new).getrecords

#create and send confirmations
Document.new(Confirmation.new).getrecords
	
#create and send shipnotices
Document.new(Shipnotice.new).getrecords
