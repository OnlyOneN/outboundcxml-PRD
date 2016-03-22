builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
	xml.doc.create_internal_subset('cXML', nil, "http://xml.cXML.org/schemas/cXML/1.2.009/Fulfill.dtd")
		xml.cXML(:payloadID => $shipnotices[$j]['payload_id'], :timestamp => $shipnotices[$j]['datetime']) {
	  		xml.Header {
				xml.From {				
					xml.Credential(:domain => $shipnotices[$j]['from_domain']) {
						xml.Identity $shipnotices[$j]['from_identity']
					}						
				}
				xml.To {
					xml.Credential(:domain => $shipnotices[$j]['to_domain']) {
						xml.Identity $shipnotices[$j]['to_identity']
					}											
				}
				xml.Sender {
					xml.Credential(:domain => $shipnotices[$j]['sender_domain']) {
						xml.Identity $shipnotices[$j]['sender_identity']
						xml.SharedSecret $shipnotices[$j]['sender_shared_secret']	
					}
					xml.UserAgent $shipnotices[$j]['user_agent']											
				}	
			}
			xml.Request {
				xml.ShipNoticeRequest {
					xml.ShipNoticeHeader(:noticeDate => $shipnotices[$j]['datetime'], :operation => 'new', :deliveryDate => $shipnotices[$j]['delivery_date'], :shipmentDate => $shipnotices[$j]['shipping_date'], :shipmentID => $shipnotices[$j]['delivery_id']) {
						xml.CustomerID $shipnotices[$j]['account_number']
						xml.Comments
					}

					if $shipnotices[$j]['tracking_number']
						trackingNumbers = $shipnotices[$j]['tracking_number'].split(";")
						k = 0
					else
						xml.ShipControl {
								xml.CarrierIdentifier(:domain => 'companyName')
								xml.ShipmentIdentifier 
						}
					end

					unless trackingNumbers.nil? || trackingNumbers.empty?
						trackingNumbers.each do
							xml.ShipControl {
								xml.CarrierIdentifier($shipnotices[$j]['carrier'], :domain => 'companyName')
								xml.ShipmentIdentifier trackingNumbers[k]
							}
							k = k + 1
						end	
					end
					xml.ShipNoticePortion {
						xml.OrderReference(:orderDate => $shipnotices[$j]['po_date'], :orderID => $shipnotices[$j]['order_id']) {
							xml.DocumentReference(:payloadID => $shipnotices[$j]['reference_id'])
						}
						xml.Comments

						i = 0
						$detailLines.each do
						
						xml.ShipNoticeItem(:lineNumber => i+1, :quantity => $detailLines[i]['quantity'].to_i) {
								xml.UnitOfMeasure 'EA'	
								xml.ManufacturerPartID $detailLines[i]['product_id']
								#xml.Description $detailLines[i]['description']
								xml.Description
							}	
						
						i = i + 1
					end
					}				
				}
			}
		}
end
$xml = builder.to_xml
puts $xml