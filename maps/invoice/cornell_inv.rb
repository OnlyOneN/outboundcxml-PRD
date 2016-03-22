builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
	xml.doc.create_internal_subset('cXML', nil, "http://xml.cXML.org/schemas/cXML/1.2.021/InvoiceDetail.dtd")
	xml.cXML(:payloadID => $invoices[$j]['payload_id'], :timestamp => $datetime) {
		xml.Header {
			xml.From {				
				xml.Credential(:domain => $invoices[$j]['from_domain']) {
					xml.Identity $invoices[$j]['from_identity']
				}						
			}
			xml.To {
				xml.Credential(:domain => $invoices[$j]['to_domain']) {
					xml.Identity $invoices[$j]['to_identity']
				}											
			}
			xml.Sender {
				xml.Credential(:domain => $invoices[$j]['sender_domain']) {
					xml.Identity $invoices[$j]['sender_identity']
					xml.SharedSecret $invoices[$j]['sender_shared_secret']
				}
				xml.UserAgent $invoices[$j]['user_agent']											
			}									
		}
		xml.Request(:deploymentMode => 'production') {
			xml.InvoiceDetailRequest {
				xml.InvoiceDetailRequestHeader(:invoiceDate => $invoices[$j]['invoice_date'], :invoiceID => $invoices[$j]['invoice_id'], :operation => 'new', :purpose => 'standard') {
					xml.InvoiceDetailHeaderIndicator
					xml.InvoiceDetailLineIndicator
					xml.InvoicePartner {
						xml.Contact(:role => 'RemitTo') {
							xml.Name('New England Biolabs', :"xml:lang" => 'en')
							xml.PostalAddress {
								xml.Street 'PO Box 3933'
								xml.City 'Boston'
								xml.State 'MA'
								xml.PostalCode '02241-3933'
								xml.Country('United States', :isoCountryCode => 'US')
							}
						}
					}
					xml.InvoicePartner {
						xml.Contact(:addressID => $invoices[$j]['external_shipto_id'], :role => 'shipTo') {
							xml.Name($invoices[$j]['shipto_name'], :"xml:lang" => 'en')
							xml.PostalAddress {
								xml.DeliverTo $invoices[$j]['shipto_line1']
								xml.DeliverTo $invoices[$j]['shipto_line2']	
								xml.Street $invoices[$j]['shipto_line3']
								xml.Street $invoices[$j]['shipto_line4']
								xml.City $invoices[$j]['shipto_city']
								xml.State $invoices[$j]['shipto_state']
								xml.PostalCode $invoices[$j]['shipto_postal_code']
								xml.Country('United States', :isoCountryCode => 'US')
							}
						}
					}
					xml.InvoicePartner {
						xml.InvoicePartner {
						xml.Contact(:addressID => $invoices[$j]['external_billto_id'], :role => 'billTo') {
							xml.Name($invoices[$j]['billto_name'], :"xml:lang" => 'en')
							xml.PostalAddress {
								xml.DeliverTo $invoices[$j]['billto_line1']
								xml.DeliverTo $invoices[$j]['billto_line2']
								xml.Street $invoices[$j]['billto_line3']
								xml.Street $invoices[$j]['billto_line4']
								xml.City $invoices[$j]['billto_city']
								xml.State $invoices[$j]['billto_state']
								xml.PostalCode $invoices[$j]['billto_postal_code']
								xml.Country('United States', :isoCountryCode => 'US')
							}
						}
					}
					xml.InvoiceDetailPaymentTerm(:payInNumberOfDays => '30', :percentageRate => '0')
				}
				xml.InvoiceDetailOrder {
					xml.InvoiceDetailOrderInfo {
						xml.OrderReference(:orderID => $invoices[$j]['order_id']) {
							xml.DocumentReference(:payloadID => $invoices[$j]['reference_id'])
						}
					}
					i = 0
				 	$tax = BigDecimal.new("0.0")
				 	$subTotal = BigDecimal.new("0.0")
					$detailLines.each do
						xml.InvoiceDetailItem(:invoiceLineNumber => i+1, :quantity => $detailLines[i]['quantity'].to_i) {
							xml.UnitOfMeasure 'EA'
							xml.UnitPrice {
								xml.Money(BigDecimal.new($detailLines[i]['item_price']).round(2).to_s("F"), :currency => 'USD')
							}
							xml.InvoiceDetailItemReference(:lineNumber => $detailLines[i]['customer_line_number']) {
								xml.ItemID {
									xml.SupplierPartID $detailLines[i]['product_id']
								}
								xml.Description($detailLines[i]['description'], :"xml:lang" => 'en')
							}
							xml.SubtotalAmount {
								xml.Money(BigDecimal.new($detailLines[i]['item_gross']).round(2).to_s("F"), :currency => 'USD')
							}
						}
						$tax = $tax + BigDecimal.new($detailLines[i]['item_tax'])
				 		$subTotal = $subTotal + BigDecimal.new($detailLines[i]['item_gross'])
						i = i + 1
					end
				}
				xml.InvoiceDetailSummary {
					xml.SubtotalAmount {
						xml.Money($subTotal.round(2).to_s("F"), :currency => 'USD')
					}
					xml.Tax {
						xml.Money($tax.round(2).to_s("F"), :currency => 'USD')
						xml.Description(:"xml:lang" => 'en')
					}
					xml.ShippingAmount {
						xml.Money(BigDecimal.new($invoices[$j]['shipping_amount']).round(2).to_s("F"), :currency => 'USD')
					}
					xml.NetAmount {
						xml.Money((BigDecimal.new($invoices[$j]['invoice_amount']) + $tax).round(2).to_s("F"), :currency => 'USD')
					}
				}
			}			
		}
	}				
end
$xml = builder.to_xml
puts $xml
File.open("#{$workingdir}/sftp/cornell/purap_einvoice_neb_#{Time.now.strftime("%FT%T%:z")}_#{rand.to_s}.xml", 'w') { |f| f.print($xml) }