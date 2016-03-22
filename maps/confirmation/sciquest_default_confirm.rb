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
			xml.Request(:deploymentMode => $deploymentmode) {
				xml.ConfirmationRequest {
					xml.ConfirmationHeader(:type => 'detail', :operation => 'new', :noticeDate => $confirmations[$j]['datetime'], :confirmID => $confirmations[$j]['confirmation_id'])
					xml.OrderReference(:orderID => $confirmations[$j]['order_id'], :orderDate => $confirmations[$j]['order_date']) {
						xml.DocumentReference(:payloadID => $confirmations[$j]['reference_id'])
					}
					i = 0
					$detailLines.each do
	
					 	if ($detailLines[i]['confirmed_quantity'].to_i == 0)
					 		xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
					 			xml.UnitOfMeasure 'EA'	
					 			xml.ConfirmationStatus(:type => 'backordered', :quantity => $detailLines[i]['ordered_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
					 				xml.UnitOfMeasure 'EA'
					 			}
					 		}	
					 	else
					 		if ($detailLines[i]['ordered_quantity'].to_i - $detailLines[i]['confirmed_quantity'].to_i > 0) 
					 			#backordered
					 			xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
					 				xml.UnitOfMeasure 'EA'	
					 				xml.ConfirmationStatus(:type => 'backordered', :quantity => $detailLines[i]['ordered_quantity'].to_i - $detailLines[i]['confirmed_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
					 					xml.UnitOfMeasure 'EA'
					 				}
					 				xml.ConfirmationStatus(:type => 'accept', :quantity => $detailLines[i]['confirmed_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
					 					xml.UnitOfMeasure 'EA'
					 				}
					 			}	
					 			else
					 				xml.ConfirmationItem(:lineNumber => $detailLines[i]['customer_line_number'].to_i, :quantity => $detailLines[i]['ordered_quantity'].to_i) {
					 				xml.UnitOfMeasure 'EA'	
					 				xml.ConfirmationStatus(:type => 'accept', :quantity => $detailLines[i]['confirmed_quantity'].to_i, :shipmentDate => $detailLines[i]['shipping_date']) {
					 					xml.UnitOfMeasure 'EA'
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
