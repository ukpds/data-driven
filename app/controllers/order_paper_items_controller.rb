require 'net/http'

class OrderPaperItemsController < ApplicationController
	include Vocabulary

	def index
		data = OrderPaperItem.all
		@order_paper_items = data[:hierarchy][:order_paper_items]

		@json_ld = json_ld(data)
		format(data)
	end

	def index_by_order_paper
		date = params[:order_paper_id]
		data = OrderPaperItem.all_by_date(date)
		@order_paper = data[:hierarchy]
		@order_paper_items = data[:hierarchy][:order_paper_items]

		@json_ld = json_ld(data)
		format(data)
	end

	def index_by_concept
		concept_uri = resource_uri(params[:concept_id])
		data = OrderPaperItem.find_by_concept(concept_uri)
		@concept = data[:hierarchy]
		@order_paper_items = data[:hierarchy][:order_paper_items]

		@json_ld = json_ld(data)
		format(data)
	end

	def index_by_person
		person_uri = resource_uri(params[:person_id])
		data = OrderPaperItem.find_by_person(person_uri)
		@person = data[:hierarchy]
		@order_paper_items = data[:hierarchy][:order_paper_items]

		@json_ld = json_ld(data)
		format(data)
	end

	def show
		order_paper_item_uri = resource_uri(params[:id])
		data = OrderPaperItem.find(order_paper_item_uri)
		@order_paper_item = data[:hierarchy]

		@json_ld = json_ld(data)
		format(data)
	end

	def edit
		order_paper_item_uri = resource_uri(params[:order_paper_item_id])
		dropdown_data = Concept.all_alphabetical
		@concepts = dropdown_data[:hierarchy].map { |concept| [ concept[:label], concept[:id] ]}.to_h

		data = OrderPaperItem.find(order_paper_item_uri)
		@order_paper_item = data[:hierarchy]
		@indexed_status = @order_paper_item[:index_label] == "indexed"
		@junk_status = @order_paper_item[:junk_label] == "junk"
		@business_item_type = @order_paper_item[:business_item_type]
		@member_role = @order_paper_item[:person][:role]

		@json_ld = json_ld(data)
		format(data)
	end

	def update
		if params[:remove]
			item_id = params[:order_paper_item_id]
			update_business_item(item_id)
			if params[:linked_concepts]
				concept_ids = params[:linked_concepts]
				concept_ids.each do |concept_id|
					update_graph(item_id, Dcterms.subject, rdf_uri(concept_id), false)
				end
			end
			redirect_to order_paper_item_edit_path(params[:order_paper_item_id])
		end

		if params[:commit]
			item_id = params[:order_paper_item_id]
			update_business_item(item_id)
			concept_id = params[:concept]
			update_graph(item_id, Dcterms.subject, rdf_uri(concept_id), true)

			redirect_to order_paper_item_edit_path(params[:order_paper_item_id])
		end

		if params[:update]
			item_id = params[:order_paper_item_id]
			update_business_item(item_id)
			redirect_to order_paper_item_edit_path(params[:order_paper_item_id])
		end
	end

	private 

	def update_graph(subject_id, predicate, object, is_insert)
		repo = SPARQL::Client::Repository.new("#{DataDriven::Application.config.database}/statements")		
		client = repo.client
		graph = RDF::Graph.new << create_pattern(subject_id, predicate, object)
		is_insert == true ? client.insert_data(graph) : client.delete_data(graph)
	end

	def create_pattern(subject_id, predicate, object)
		s = rdf_uri(subject_id)
		p = predicate
		o = object
		RDF::Statement(s, p, o)
	end

	def update_business_item(item_id)
		index_junk_check(item_id)
		business_item_type_update(item_id)
		member_role_update(item_id)
	end

	def index_junk_check(item_id)
		params[:index_checked] ? update_graph(item_id, Parl.indexed, 'indexed', true) : update_graph(item_id, Parl.indexed, 'indexed', false)
		params[:junk_checked] ? update_graph(item_id, Parl.junk, 'junk', true) : update_graph(item_id, Parl.junk, 'junk', false)
	end

	def business_item_type_update(item_id)
		current_business_item_type = params[:current_business_item_type]
		new_business_item_type = params[:new_business_item_type]
		update_graph(item_id, Parl.businessItemType, current_business_item_type, false) 
		update_graph(item_id, Parl.businessItemType, new_business_item_type, true) unless new_business_item_type == "" 
	end

	def member_role_update(item_id)
		current_role = params[:current_member_role]
		new_role = params[:new_member_role]
		update_graph(item_id, Parl.memberRole, current_role, false) 
		update_graph(item_id, Parl.memberRole, new_role, true) unless new_role == ""
	end
end