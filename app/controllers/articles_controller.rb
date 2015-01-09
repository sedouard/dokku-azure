class ArticlesController < ApplicationController
	def new
	end
	def show
		puts Article.find(params[:id]).inspect
		@article = Article.find(params[:id])
	end
	def create

		@article = Article.new(params.require(:article).permit(:title, :text))

		@article.save
		redirect_to @article
	end
	def index
		@articles = Article.all
	end
end
