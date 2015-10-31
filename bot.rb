require 'bundler/setup'

Bundler.require

CHANNEL = '#emberjs-test'
TIMEOUT = 2 #5 * 60
debouncer = nil


class Debouncer
  def initialize timeout, &block
    @timeout, @block = timeout, block
  end

  def trigger
    @thread.kill if @thread
    @thread = Thread.new do
      sleep @timeout
      @block.call
    end
  end
end



bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = [CHANNEL]
    c.nick = "Slackbot"
    debouncer = Debouncer.new TIMEOUT do
      channel = channels.find{|c| c.name == CHANNEL}
      badge = Net::HTTP.get URI('https://ember-community-slackin.herokuapp.com/badge.svg')
      doc = Nokogiri::XML(badge)
      online_count = doc.search('text').last.inner_text.split('/').first

      channel.send "It looks like no-one replied. There are currently #{online_count} people online in slack, why not try there?"
      channel.send 'https://ember-community-slackin.herokuapp.com'
    end
  end

  on :message do |m|
    debouncer.trigger
  end
end


bot.start
