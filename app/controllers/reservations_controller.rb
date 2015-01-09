class ReservationsController < ApplicationController
	def new
	end
	def show
		puts Reservation.find(params[:id]).inspect
		@reservation = Reservation.find(params[:id])
	end
	def create

		@reservation = Reservation.new(params.require(:reservation).permit(:date_time, :party_size, :name))

		@reservation.save
		redirect_to @reservation
	end
	def index
		@reservations = Reservation.all
	end
end
