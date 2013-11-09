class AyaDN
	class AppdotnetSendPost
		@url
		@token
		def initialize(token)
			@url = 'https://alpha-api.app.net/stream/0/posts'
			@token = token
		end
		def createPost(text)
			uri = URI("#{@url}")
			https = Net::HTTP.new(uri.host,uri.port)
			https.use_ssl = true
			request = Net::HTTP::Post.new(uri.path)
			request["Authorization"] = "Bearer #{@token}"
			request["Content-Type"] = "application/json"

			payload = {
				"text" => "#{text}"
			}.to_json

			response = https.request(request, payload)
			callback = response.body

			blob = JSON.parse(callback)
			adnData = blob['data']
			postText = adnData['text']
			coloredPost = colorize(postText)
			userSentPost = ""
			userName = adnData['user']['username']
			createdAt = adnData['created_at']
			createdDay = createdAt[0...10]
			createdHour = createdAt[11...19]
			links = adnData['entities']['links']
			userSentPost += "\nPost envoyé le " + createdDay.cyan + ' à ' + createdHour.cyan + ' par ' + "@".green + userName.green + " :\n" + "---\n".red + coloredPost + "\n\n"
			postId = adnData['id']
			userSentPost += "Post ID : ".cyan + postId.to_s.brown
			if !links.empty?
				userSentPost += " - " + "Lien : ".cyan
				links.each do |link|
					linkURL = link['url']
					userSentPost += linkURL.brown + " "
				end
			end
			userSentPost += "\n\n\n"

		return userSentPost
		end
	end
end
