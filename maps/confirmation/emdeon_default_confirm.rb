builder = Nokogiri::XML::Builder.new do |xml|
	xml.doc.create_internal_subset('cXML', nil, "http://xml.cXML.org/schemas/cXML/1.2.009/Fulfill.dtd")
		xml.cXML(:payloadID => $confirmations[$j]['payload_id'], :timestamp => $confirmations[$j]['datetime']) {
	  		xml.Header {
				xml.From {				
					xml.Credential(:domain => $confirmations[$j]['from_domain']) {
						xml.Identity $confirmations[$j]['from_identity']
					}						
				}
				xml.To {
					xml.Credential(:domain => $confirmations[$j]['to_domain']) {
						xml.Identity $confirmations[$j]['to_identity']
					}											
				}
				xml.Sender {
					xml.Credential(:domain => $confirmations[$j]['sender_domain']) {
						xml.Identity $confirmations[$j]['sender_identity']
						xml.SharedSecret $confirmations[$j]['sender_shared_secret']	
					}
					xml.UserAgent $confirmations[$j]['user_agent']											
				}	
			}
			i = 0
			$tax = BigDecimal.new("0.0")
			$detailLines.each do
				$tax = $tax + BigDecimal.new($detailLines[i]['tax_amount'])
				i = i + 1
			end

			xml.Request(:deploymentMode => $deploymentmode) {
				xml.ConfirmationRequest {
					xml.ConfirmationHeader(:type => 'detail', :operation => 'new', :noticeDate => $confirmations[$j]['datetime'], :confirmID => $confirmations[$j]['confirmation_id'])
					xml.Shipping {
						xml.Money(BigDecimal.new($confirmations[$j]['shipping_amount']).round(2).to_s("F"), :currency => 'USD')
					}
					xml.Tax {
						xml.Money($tax.round(2).to_s("F"), :currency => 'USD')
					}
					xml.Contact {
						xml.Name $confirmations[$j]['shipto_name']
						xml.PostalAddress {
							xml.DeliverTo $confirmations[$j]['shipto_line1']
							xml.DeliverTo $confirmations[$j]['shipto_line2']
							xml.Street $confirmations[$j]['shipto_line3']
							xml.Street $confirmations[$j]['shipto_line4']
							xml.City $confirmations[$j]['shipto_city']
							xml.State $confirmations[$j]['shipto_state']
							xml.PostalCode $confirmations[$j]['shipto_postal_code']
							xml.Country $confirmations[$j]['shipto_country']
						}
					}
					xml.Comments "#{$confirmations[$j]['soldto_id']}_#{$confirmations[$j]['shipto_id']}"
					xml.OrderReference(:orderID => $confirmations[$j]['order_id'], :orderDate => $confirmations[$j]['order_date']) {
						xml.DocumentReference(:payloadID => $confirmations[$j]['reference_id'])
					}
					i = 0
					$detailLines.each do
	
						if ($detailLines[i]['confirmed_quantity'].to_i == 0)
							xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
								xml.UnitOfMeasure $detailLines[i]['unit_of_measure']	
								xml.ConfirmationStatus(:type => 'backordered', :quantity => $detailLines[i]['ordered_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
									xml.UnitOfMeasure $detailLines[i]['unit_of_measure']	
									xml.UnitPrice {
										xml.Money(BigDecimal.new($detailLines[i]['net_price']).round(2).to_s("F"), :currency => $detailLines[i]['currency'])
									}
								}
							}	
						else
							if ($detailLines[i]['ordered_quantity'].to_i - $detailLines[i]['confirmed_quantity'].to_i > 0) 
								#backordered
								xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
									xml.UnitOfMeasure $detailLines[i]['unit_of_measure']		
									xml.ConfirmationStatus(:type => 'backordered', :quantity => $detailLines[i]['ordered_quantity'].to_i - $detailLines[i]['confirmed_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
										xml.UnitOfMeasure $detailLines[i]['unit_of_measure']	
										xml.UnitPrice {
											xml.Money(BigDecimal.new($detailLines[i]['net_price']).round(2).to_s("F"), :currency => $detailLines[i]['currency'])
										}
									}
									xml.ConfirmationStatus(:type => 'accept', :quantity => $detailLines[i]['ordered_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
										xml.UnitOfMeasure $detailLines[i]['unit_of_measure']	
										xml.UnitPrice {
											xml.Money(BigDecimal.new($detailLines[i]['net_price']).round(2).to_s("F"), :currency => $detailLines[i]['currency'])
										}
									}
								}	
								else
									xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
										xml.UnitOfMeasure $detailLines[i]['unit_of_measure']	
										xml.ConfirmationStatus(:type => 'accept', :quantity => $detailLines[i]['confirmed_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
										xml.UnitOfMeasure $detailLines[i]['unit_of_measure']
										xml.UnitPrice {
											xml.Money(BigDecimal.new($detailLines[i]['net_price']).round(2).to_s("F"), :currency => $detailLines[i]['currency'])
										}
									}
								}	
							end
						end 
	
						i = i + 1
					end
				}
			}
		}
end
$xml = builder.to_xml
puts $xml
File.open("#{$workingdir}/sftp/emdeon/#{$confirmations[$j]['payload_id']}.xml", 'w') { |f| f.print($xml) }