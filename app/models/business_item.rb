class BusinessItem < QueryObject
	include Vocabulary

	def self.all(date)
		result = self.query("
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
			PREFIX schema: <http://schema.org/>
			CONSTRUCT {
			    ?orderPaperItem
			        dcterms:title ?title ;
    				schema:previousItem ?previousItem .
			}
			WHERE { 
    			SELECT ?orderPaperItem ?title ?previousItem 
    			WHERE {
        			?orderPaperItem 
			        	a parl:OrderPaperItem ;
			        	dcterms:date \"#{date}\"^^xsd:date ;
			    		dcterms:title ?title . 
        			OPTIONAL {
    					?orderPaperItem 
    						schema:previousItem ?previousItem .
    				}
				}
			}
		")

		order_paper_items = result.subjects.map do |subject|
			title_pattern = RDF::Query::Pattern.new(
		  		subject, 
		  		Dcterms.title, 
		  		:title)
			title = result.first_literal(title_pattern).to_s
			previous_pattern = RDF::Query::Pattern.new(
		  		subject, 
		  		Schema.previousItem, 
		  		:previousItem)
			previousItemURI = result.first_object(previous_pattern)

			{
				:id => self.get_id(subject),
				:title => title,
				:previousItemId => self.get_id(previousItemURI)
			}
		end

		hierarchy = {
			:date => date.to_datetime,
			:order_paper_items => order_paper_items
		}

		{ :graph => result, :hierarchy => hierarchy }
	end

	def self.find(uri)
		result = self.query("
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
			PREFIX schema: <http://schema.org/>
			CONSTRUCT {
			    ?item
			        dcterms:date ?date ;
			    	dcterms:title ?title ;
        			dcterms:identifier ?identifier ;
            		dcterms:abstract ?abstract ;
            		schema:previousItem ?previousItem .
            	?person
            		schema:name ?person_name .
			}
			WHERE { 
    			SELECT ?item ?date ?title ?identifier ?person ?abstract ?previousItem ?person_name
    			WHERE {
        			?item
			        	a parl:OrderPaperItem ;
			        	dcterms:date ?date ;
			    		dcterms:title ?title ;
        				dcterms:identifier ?identifier .

        	  	OPTIONAL {
        			?item
            			parl:member ?person .
            		?person
                        schema:name ?person_name .
        		}
        		OPTIONAL {
            		?item
            			dcterms:abstract ?abstract ;
        		}
            	OPTIONAL {
            		?item
                       	schema:previousItem ?previousItem ;
        		}		
         		FILTER(?item = <#{uri}>)
    		}      
		}")

		date_pattern = RDF::Query::Pattern.new(
		  	RDF::URI.new(uri), 
		  	Dcterms.date, 
		  	:date)
		date = result.first_object(date_pattern).to_s.to_datetime
		title_pattern = RDF::Query::Pattern.new(
		  	RDF::URI.new(uri), 
		  	Dcterms.title, 
		  	:title)
		title = result.first_literal(title_pattern).to_s
		person_pattern = RDF::Query::Pattern.new(
		  	:person, 
		  	Schema.name, 
		  	:name)
		person = result.first_subject(person_pattern)
		person_name = result.first_literal(person_pattern).to_s
		abstract_pattern = RDF::Query::Pattern.new(
		  	RDF::URI.new(uri), 
		  	Dcterms.abstract, 
		  	:abstract)
		abstract = result.first_literal(abstract_pattern).to_s
		previous_pattern = RDF::Query::Pattern.new(
		  	RDF::URI.new(uri), 
		  	Schema.previousItem, 
		  	:previousItem)
		previousItemURI = result.first_object(previous_pattern)

		hierarchy = 
			{
				:id => self.get_id(uri),
				:date => date,
				:title => title,
				:person => {
					:id => self.get_id(person),
					:name => person_name
					},
				:abstract => abstract,
				:previousItemId => self.get_id(previousItemURI)
			}

		{ :graph => result, :hierarchy => hierarchy }
	end

	def self.update
		self.insert("
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			INSERT {
			    <http://id.ukpds.org/23a6596b-bc6c-4577-a9d7-0670fcdfe180> dcterms:subject <http://id.ukpds.org/00090502-0000-0000-0000-000000000002>
			}
			WHERE {
			    
			}
		")
	end
end