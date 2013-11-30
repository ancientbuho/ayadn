#!/usr/bin/ruby
# encoding: utf-8
class AyaDN
	def initialize(token)
		@token = token
		@api = AyaDN::API.new(@token)
		@view = AyaDN::View
	end

	def stream
		$tools.fileOps("makedir", $ayadn_lastPageID_path)
	 	puts @view.new(@hash).showStream
	end
	def completeStream
		$tools.fileOps("makedir", $ayadn_lastPageID_path)
	    stream, pagination_array = @view.new(@hash).showCompleteStream
	    lastPageID = pagination_array.last
		return stream, lastPageID
	end
	def debugStream
		puts @view.new(@hash).showDebugStream
	end
	def ayadnDebugStream
		@hash = @api.getUnified
		debugStream
	end
	def ayadnDebugPost(postID)
		@hash = @api.getPostInfos("call", postID)
		debugStream
	end

	def ayadnAuthorize(action)
		$tools.fileOps("makedir", $ayadn_authorization_path)
		if action == "reset"
			$tools.fileOps("reset", "credentials")
		end
		auth_token = $tools.fileOps("auth", "read")
		if auth_token == nil
			url = @api.makeAuthorizeURL
			$tools.startBrowser(url)
			puts "\nAyaDN opened a browser to authorize via App.net very easily. Just login with your App.net account, then copy the code it will give you, paste it here then press [ENTER].".pink + " Paste authorization code: \n\n".brown
			auth_token = STDIN.gets.chomp()
			$tools.fileOps("auth", "write", auth_token)
			puts "\nThank you for authorizing AyaDN. You won't need to do this anymore.\n\n".green
			sleep 3
			puts $tools.helpScreen
			puts "Enjoy!\n".cyan
		end
	end

	def displayStream(stream)
		!stream.empty? ? (puts stream) : (puts "No new posts since your last visit.\n\n".red)
	end
	def displayScrollStream(stream)
		!stream.empty? ? (puts stream) : (print "\r")
	end
	def ayadnScroll(value, target)
		value = "unified" if value == nil
		if target == nil
			fileURL = $ayadn_lastPageID_path + "/lastPageID-#{value}"
		else
			fileURL = $ayadn_lastPageID_path + "/lastPageID-#{value}-#{target}"
		end
		while true
			begin
				print "\r                                         "
				print "\r"
				lastPageID = $tools.fileOps("getlastpageid", fileURL)
				if value == "global"
					@hash = @api.getGlobal(lastPageID)
				elsif value == "unified"
					@hash = @api.getUnified(lastPageID)
				elsif value == ("checkins" || "photos" || "conversations" || "trending")
					@hash = @api.getExplore(value, lastPageID)
				elsif value == "mentions"
					@hash = @api.getUserMentions(target, lastPageID)
				elsif value == "posts"
					@hash = @api.getUserPosts(target, lastPageID)
				end
				stream, lastPageID = completeStream
				displayScrollStream(stream)
				if lastPageID != nil
					$tools.fileOps("writelastpageid", fileURL, lastPageID)
					print "\r                                         "
            		puts "\n\n"
            		$tools.countdown($countdown_1)
            	else
        			print "\rNo new posts                ".red
        			sleep 2
        			$tools.countdown($countdown_2)
        		end					
			rescue Exception => e
				abort("\nStopped.\n\n".red)
			end
		end
	end
	def ayadnInteractions
		puts $status.getInteractions
		#$tools.fileOps("makedir", $ayadn_lastPageID_path)
		#fileURL = $ayadn_lastPageID_path + "/lastPageID-interactions"
		#lastPageID = $tools.fileOps("getlastpageid", fileURL)
		@hash = @api.getInteractions
		#$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		stream, lastPageID = @view.new(@hash).showInteractions
		puts stream + "\n\n"
	end
	def ayadnGlobal
		puts $status.getGlobal
		fileURL = $ayadn_lastPageID_path + "/lastPageID-global"
		lastPageID = $tools.fileOps("getlastpageid", fileURL)
		@hash = @api.getGlobal(lastPageID)
		stream, lastPageID = completeStream
		$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		displayStream(stream)
	end
	def ayadnUnified
		fileURL = $ayadn_lastPageID_path + "/lastPageID-unified"
		lastPageID = $tools.fileOps("getlastpageid", fileURL)
		puts $status.getUnified
		@hash = @api.getUnified(lastPageID)
		stream, lastPageID = completeStream
		$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		displayStream(stream)
	end
	def ayadnHashtags(tag)
		puts $status.getHashtags(tag)
		@hash = @api.getHashtags(tag)
		stream, lastPageID = completeStream
		displayStream(stream)
	end
	def ayadnExplore(explore)
		fileURL = $ayadn_lastPageID_path + "/lastPageID-#{explore}"
		lastPageID = $tools.fileOps("getlastpageid", fileURL)
		puts $status.getExplore(explore)
		@hash = @api.getExplore(explore, lastPageID)
		stream, lastPageID = completeStream
		$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		displayStream(stream)
	end
	def ayadnUserMentions(name)
		fileURL = $ayadn_lastPageID_path + "/lastPageID-mentions-#{name}"
		lastPageID = $tools.fileOps("getlastpageid", fileURL)
		puts $status.mentionsUser(name)
		@hash = @api.getUserMentions(name, lastPageID)
		stream, lastPageID = completeStream
		$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		displayStream(stream)
	end
	def ayadnUserPosts(name)
		fileURL = $ayadn_lastPageID_path + "/lastPageID-posts-#{name}"
		lastPageID = $tools.fileOps("getlastpageid", fileURL)
		puts $status.postsUser(name)
		@hash = @api.getUserPosts(name, lastPageID)
		stream, lastPageID = completeStream
		$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
		displayStream(stream)
	end
	def ayadnUserInfos(name)
		puts $status.infosUser(name)
		@hash = @api.getUserInfos(name)
	    puts @view.new(@hash).showUsersInfos(name)
	end
	
	def ayadnSendMessage(target, text)
		abort($status.emptyPost) if (text.empty? || text == nil)
		puts "\nSending private Message...\n".green
		callback = @api.httpSendMessage(target, text)
		blob = JSON.parse(callback)
		@hash = blob['data']
		privateMessageChannelID = @hash['channel_id']
		privateMessageThreadID = @hash['thread_id']
		privateMessageID = @hash['id']
		$tools.fileOps("makedir", $ayadn_messages_path)
		puts "Channel ID: ".cyan + privateMessageChannelID.brown + " Message ID: ".cyan + privateMessageID.brown + "\n\n"
		puts $status.postSent
		$tools.fileOps("savechannelid", privateMessageChannelID, target)
	end
	def ayadnGetMessages(target, action = nil)
		if target != nil
			fileURL = $ayadn_lastPageID_path + "/lastPageID-channels-#{target}"
			lastPageID = $tools.fileOps("getlastpageid", fileURL) unless action == "all"
			@hash = @api.getMessages(target, lastPageID)
			messagesString, lastPageID = @view.new(@hash).showMessagesFromChannel
			$tools.fileOps("writelastpageid", fileURL, lastPageID) unless lastPageID == nil
			displayStream(messagesString)
		else
			@hash = @api.getChannels
			theChannels, channels_list = @view.new(@hash).showChannels
			puts theChannels
		end
	end
	def ayadnSendPost(text, reply_to = nil)
		abort($status.emptyPost) if (text.empty? || text == nil)
		puts $status.sendPost
		callback = @api.httpSend(text, reply_to)
		blob = JSON.parse(callback)
		@hash = blob['data']
		puts @view.new(@hash).buildPostInfo(@hash, isMine = true)
		puts $status.postSent
		# show end of the stream after posting
		if reply_to.empty?
			@hash = @api.getSimpleUnified
			stream, lastPageID = completeStream
			displayStream(stream)
		else
			@hash1 = @api.getPostReplies(reply_to)
			@hash2 = @api.getSimpleUnified
			@hash = @hash1.merge!(@hash2)
			stream, lastPageID = completeStream
			displayStream(stream)
		end
	end
	def ayadnComposeMessage(target)
		puts $status.writeMessage
		maxChar = 2048
		begin
			inputText = STDIN.gets.chomp
		rescue Exception => e
			abort("\n\nCanceled. Your message hasn't been sent.\n\n".red)
		end
		toRegex = inputText.dup
		withoutMarkdown = $tools.getMarkdownText(toRegex)
		realLength = withoutMarkdown.length
		if realLength < 2048
			ayadnSendMessage(target, inputText)
		else
			abort("\nError: your message is ".red + "#{realLength} ".brown + " characters long, please remove ".red + "#{realLength - maxChar} ".brown + "characters.\n\n".red)
		end
	end
	def ayadnComposePost(reply_to = "", mentionsList = "", myUsername = "")
		puts $status.writePost
		maxChar = 256
		charCount = maxChar - mentionsList.length
		text = mentionsList
		if !mentionsList.empty?
			text += " "
			charCount -= 1
		end
		print "\n#{text}"
		begin
			inputText = STDIN.gets.chomp
		rescue Exception => e
			abort("\n\nCanceled. Your post hasn't been sent.\n\n".red)
		end
		postText = text + inputText
		toRegex = postText.dup
		withoutMarkdown = $tools.getMarkdownText(toRegex)
		totalLength = charCount - withoutMarkdown.length
		realLength = maxChar + totalLength.abs
		if totalLength > 0
			ayadnSendPost(postText, reply_to)
		else
			abort("\nError: your post is ".red + "#{realLength} ".brown + " characters long, please remove ".red + "#{realLength - maxChar} ".brown + "characters.\n\n".red)
		end
	end
	def ayadnReply(postID)
		puts "Replying to post ".cyan + "#{postID}...\n".brown
		rawMentionsText, replyingToThisUsername, isRepost = @api.getPostMentions(postID) 
		if isRepost != nil
			puts "\n#{postID} ".brown + " is a repost.\n".red
			postID = isRepost['id']
			puts "Redirecting to the original post: ".cyan + "#{postID}\n".brown
			rawMentionsText, replyingToThisUsername, isRepost = @api.getPostMentions(postID) 
		end
		content = Array.new
		splitted = rawMentionsText.split(" ")
		splitted.each do |word|
			content.push(word) if word =~ /^@/
		end
		# detect if mentions include myself
		myUsername = @api.getUserName("me")
		myHandle = "@" + myUsername
		replyingToHandle = "@" + replyingToThisUsername
		newContent = Array.new
		# if I'm not answering myself, add the @username of the "replyee"
		newContent.push(replyingToHandle) if replyingToThisUsername != myUsername 
		content.each do |item|
			# if I'm in the post's mentions, erase me, else insert the mention
			item == myHandle ? newContent.push("") : newContent.push(item)
		end
		mentionsList = newContent.join(" ")
		ayadnComposePost(postID, mentionsList)
	end
	def ayadnDeletePost(postID)
		puts $status.deletePost(postID)
		isTherePost, isYours = @api.goDelete(postID)
		if isTherePost == nil
			abort("\nPost already deleted.\n\n".red)
		else
			@api.restDelete()
			puts "\nPost successfully deleted.\n\n".green
			exit
		end
	end
	def ayadnWhoReposted(postID)
		puts $status.whoReposted(postID)
		@hash = @api.getWhoReposted(postID)
		abort("\nThis post hasn't been reposted by anyone.\n\n".red) if @hash['data'].empty?
	    puts @view.new(@hash).showUsersList()
	end
	def ayadnWhoStarred(postID)
		puts $status.whoStarred(postID)
		@hash = @api.getWhoStarred(postID)
		abort("\nThis post hasn't been starred by anyone.\n\n".red) if @hash['data'].empty?
	    puts @view.new(@hash).showUsersList()
	end
	def ayadnStarredPosts(name)
		puts $status.starsUser(name)
		@hash = @api.getStarredPosts(name)
		stream, lastPageID = completeStream
		displayStream(stream)
	end
	def ayadnConversation(postID)
		puts $status.getPostReplies(postID)
		@hash = @api.getPostReplies(postID)
		stream, lastPageID = completeStream
		displayStream(stream)
	end
	def ayadnPostInfos(action, postID)
		puts $status.infosPost(postID)
		@hash = @api.getPostInfos(action, postID)
	    puts @view.new(@hash).showPostInfos(postID, isMine = false)
	end
	def getList(list, name)
		beforeID = nil
		bigHash = {}
		if list == "followers"
			@hash = @api.getFollowers(name, beforeID)
		elsif list == "followings"
			@hash = @api.getFollowings(name, beforeID)
		elsif list == "muted"
			@hash = @api.getMuted(name, beforeID)
		end
		usersHash, pagination_array = @view.new(@hash).buildFollowList()
	    bigHash.merge!(usersHash)
	    beforeID = pagination_array.last
	    while pagination_array != nil
			if list == "followers"
				@hash = @api.getFollowers(name, beforeID)
			elsif list == "followings"
				@hash = @api.getFollowings(name, beforeID)
			elsif list == "muted"
				@hash = @api.getMuted(name, beforeID)
			end
		    usersHash, pagination_array = @view.new(@hash).buildFollowList()
		    bigHash.merge!(usersHash)
	    	break if pagination_array.first == nil
	    	beforeID = pagination_array.last
		end
	    return bigHash
	end

	def ayadnShowList(list, name)
		puts "\nFetching the \'#{list}\' list. Please wait...\n\n".green
		@hash = getList(list, name)
		if list == "muted"
			puts "Your list of muted users:\n".green
		elsif list == "followings"
			puts "List of users you're following:\n".green
		elsif list == "followers"
			puts "List of users following you:\n".green
		end
		users, number = @view.new(@hash).showUsers()
		puts users
		puts "Number of users: ".green + " #{number}\n".brown
	end

	def ayadnSaveList(list, name) # to be called with: var = ayadnSaveList("followers", "@ericd")
		file = "/#{name}-#{list}.json"
		fileURL = $ayadn_lists_path + file
		unless Dir.exists?$ayadn_lists_path
			puts "Creating lists directory in ".green + "#{$ayadn_data_path}".brown + "\n"
			FileUtils.mkdir_p $ayadn_lists_path
		end
		if File.exists?(fileURL)
			puts "\nYou already saved this list.\n".red
			puts "Delete the old one and replace with this one?\n".red + "(n/y) ".green 
			input = STDIN.getch
			abort("\nCanceled.\n\n".red) if input == ("n" || "N")
		end
		if list == "muted"
			puts "\nFetching your muted users list.\n".cyan
		else
			puts "\nFetching ".cyan + "#{name}".brown + "'s list of #{list}.\n".cyan
		end
		puts "Please wait...\n".green
		followList = getList(list, name)
		puts "Saving the list...\n".green
		f = File.new(fileURL, "w")
			f.puts(followList.to_json)
		f.close
		puts "\nSuccessfully saved the list.\n\n".green
		exit
	end

	def ayadnSavePost(postID)
		name = postID.to_s
		unless Dir.exists?$ayadn_posts_path
			puts "Creating posts directory in ".green + "#{$ayadn_data_path}...".brown
			FileUtils.mkdir_p $ayadn_posts_path
		end
		file = "/#{name}.post"
		fileURL = $ayadn_posts_path + file
		if File.exists?(fileURL)
			abort("\nYou already saved this post.\n\n".red)
		end
		puts "\nLoading post ".green + "#{postID}".brown
		@hash = @api.getSinglePost(postID)
		puts $status.savingFile(name, $ayadn_posts_path, file)
		f = File.new(fileURL, "w")
			f.puts(@hash)
		f.close
		puts "\nSuccessfully saved the post.\n\n".green
		exit
	end

	# could be used in many places if needed
	def ayadnGetOriginalPost(postID)
		originalPostID = @api.getOriginalPost(postID)
	end
	#

	def ayadnSearch(value)
		@hash = @api.getSearch(value)
		stream, lastPageID = completeStream
		displayStream(stream)
	end

	def ayadnFollowing(action, name)
		youFollow, followsYou = @api.getUserFollowInfo(name)
		if action == "follow"
			if youFollow == true
				abort("You're already following this user.\n\n".red)
			else
				resp = @api.followUser(name)
				puts "\nYou just followed user ".green + "#{name}".brown + "\n\n"
			end
		elsif action == "unfollow"
			if youFollow == false
				abort("You're already not following this user.\n\n".red)
			else
				resp = @api.unfollowUser(name)
				puts "\nYou just unfollowed user ".green + "#{name}".brown + "\n\n"
			end
		else
			abort("\nsyntax error\n")
		end
	end

	def ayadnMuting(action, name)
		youMuted = @api.getUserMuteInfo(name)
		if action == "mute"
			if youMuted == "true"
				abort("You've already muted this user.\n\n".red)
			else
				resp = @api.muteUser(name)
				puts "\nYou just muted user ".green + "#{name}".brown + "\n\n"
			end
		elsif action == "unmute"
			if youMuted == "false"
				abort("This user is not muted.\n\n".red)
			else
				resp = @api.unmuteUser(name)
				puts "\nYou just unmuted user ".green + "#{name}".brown + "\n\n"
			end
		else
			abort("\nsyntax error\n")
		end
	end

	def ayadnStarringPost(action, postID)
		@hash = @api.getSinglePost(postID)
		postInfo = @hash['data']
		youStarred = postInfo['you_starred']
		isRepost = postInfo['repost_of']
		if isRepost != nil
			puts "\n#{postID} ".brown + " is a repost.\n".red
			puts "Redirecting to the original post.\n".cyan
			postID = isRepost['id']
			youStarred = isRepost['you_starred']
		end
		if action == "star"
			if youStarred == false
				puts "\nStarring post ".green + "#{postID}\n".brown
				resp = @api.starPost(postID)
				puts "\nSuccessfully starred the post.\n\n".green
			else
				abort("Canceled: the post is already starred.\n\n".red)
			end
		elsif action == "unstar"
			if youStarred == false
				abort("Canceled: the post wasn't already starred.\n\n".red)
			else
				puts "\nUnstarring post ".green + "#{postID}\n".brown
				resp = @api.unstarPost(postID)
				puts "\nSuccessfully unstarred the post.\n\n".green
			end
		else
			abort("\nsyntax error\n".red)
		end
	end
	def ayadnReposting(action, postID)
		@hash = @api.getSinglePost(postID)
		postInfo = @hash['data']
		isRepost = postInfo['repost_of']
		youReposted = postInfo['you_reposted']
		if isRepost != nil && youReposted == false
			puts "\n#{postID} ".brown + " is a repost (but not by you).\n".red
			puts "Redirecting to the original post.\n".cyan
			postID = isRepost['id']
			youReposted = isRepost['you_reposted']
		end
		if action == "repost"
			if youReposted == false
				puts "\nReposting post ".green + "#{postID}\n".brown
				resp = @api.repostPost(postID)
				puts "\nSuccessfully reposted the post.\n\n".green
			else
				abort("Canceled: you already reposted this post.\n\n".red)
			end
		elsif action == "unrepost"
			if youReposted == true
				puts "\nUnreposting post ".green + "#{postID}\n".brown
				resp = @api.unrepostPost(postID)
				puts "\nSuccessfully unreposted the post.\n\n".green
			else
				abort("Canceled: this post wasn't reposted by you.\n\n".red)
			end
		else
			abort("\nsyntax error\n".red)
		end
	end
	def ayadnReset(target, content, option)
		$tools.fileOps("reset", target, content, option)
	end
end













