# encoding: utf-8
class AyaDN
	class AppdotnetHashtagSearch
		@url
		def initialize
			@url = 'https://alpha-api.app.net/stream/0/posts/tag/'
		end
		def getHashtag(hashtag)
			@url += "#{hashtag}"
			begin
				response = RestClient.get(@url)
				return response.body
			rescue
				warnings = ErrorWarning.new
				puts warnings.errorHTTP
			end
		end
		def getJSON(hashtag)
			return getHashtag(hashtag)
		end
		def getTaggedPosts(hashtag)
			hashOfResponse = JSON.parse(getJSON(hashtag))
			hashtagData = hashOfResponse['data']
			hashtagList = hashtagData.reverse
			builder = AyaDN::BuildPosts.new
			resp = builder.buildPost(hashtagList)
			return resp
		end
	end
end