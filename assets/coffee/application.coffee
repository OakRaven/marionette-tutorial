@MyApp = new Backbone.Marionette.Application()

MyApp.addRegions
	mainRegion: "#content"

AngryCat = Backbone.Model.extend
	defaults:
		votes: 0

	addVote: ->
		@set( 'votes', @get('votes') + 1 )

	rankUp: ->
		@set {rank: (@get('rank') - 1)}

	rankDown: ->
		@set {rank: (@get('rank') + 1)}

AngryCats = Backbone.Collection.extend

	model: AngryCat

	initialize: (cats) ->
		rank = 1

		_.each cats, (cat) ->
			cat.set "rank", rank
			++rank

		@on 'add', (cat) ->
			unless cat.get('rank')
				error = Error('Cat must have a rank defined before being added to the collection')
				error.name = "NoRankError"
				throw error

		self = this

		MyApp.vent.on "rank:up", (cat) ->
			return true if cat.get("rank") is 1
			self.rankUp(cat)
			self.sort()

		MyApp.vent.on "rank:down", (cat) ->
			return true if cat.get("rank") is self.size()
			self.rankDown(cat)
			self.sort()

		MyApp.vent.on "cat:disqualify", (cat) ->
			disqualifiedRank = cat.get('rank')
			catsToUpRank = self.filter (cat) ->
				cat.get('rank') > disqualifiedRank

			catsToUpRank.forEach (cat) ->
				cat.rankUp()

			self.trigger 'reset'

	comparator: (cat) ->
		cat.get 'rank'

	rankUp: (cat) ->
		rankToSwap = cat.get("rank") - 1
		otherCat = this.at(rankToSwap - 1)

		cat.rankUp()
		otherCat.rankDown()

	rankDown: (cat) ->
		rankToSwap = cat.get('rank') + 1
		otherCat = this.at(rankToSwap - 1)

		cat.rankDown()
		otherCat.rankUp()


AngryCatView = Backbone.Marionette.ItemView.extend
	template: "#angry_cat-template"
	tagName: "tr"
	className: "angry_cat"

	events:
		"click .rank_up img": "rankUp"
		"click .rank_down img": "rankDown"
		"click a.disqualify": "disqualify"

	disqualify: ->
		MyApp.vent.trigger "cat:disqualify", @model
		@model.destroy()

	rankUp: ->
		@model.addVote()
		MyApp.vent.trigger "rank:up", this.model

	rankDown: ->
		@model.addVote()
		MyApp.vent.trigger "rank:down", this.model

AngryCatsView = Backbone.Marionette.CompositeView.extend
	tagName: "table"
	id: "angry_cats"
	className: "table-striped table-bordered"
	template: "#angry_cats-template"
	itemView: AngryCatView

	appendHtml: (collectionView, itemView) ->
		collectionView.$("tbody").append itemView.el

MyApp.addInitializer (options) ->
	angryCatsView = new AngryCatsView
		collection: options.cats

	MyApp.mainRegion.show angryCatsView

$(document).ready ->
	cats = new AngryCats [
		new AngryCat { name: 'Marshmellow', image_path: 'assets/images/cat1.jpg' }
		new AngryCat { name: 'Pancake', image_path: 'assets/images/cat2.jpg' }
		new AngryCat { name: 'Fuzzy', image_path: 'assets/images/cat3.jpg' }
		new AngryCat { name: 'Domino', image_path: 'assets/images/cat4.jpg' }
	]

	MyApp.start { cats: cats }

	cats.add(
		new AngryCat(
			name: 'Cranky Cat'
			image_path: 'assets/images/cat5.jpg'
			rank: cats.size() + 1
		)
	)