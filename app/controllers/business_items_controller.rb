class BusinessItemsController < ApplicationController
	def index
		date = params[:order_paper_id]
		data = BusinessItem.all(date)
		@order_paper = data[:hierarchy]

		@json_ld = json_ld(data)
		format(data)
	end

	def show
		
	end

end