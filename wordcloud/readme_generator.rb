require_relative "./cloud_types"

class ReadmeGenerator
  WORD_CLOUD_URL = 'https://raw.githubusercontent.com/pedroffd/pedroffd/master/wordcloud/wordcloud.png'
  ADDWORD = 'add'
  SHUFFLECLOUD = 'shuffle'
  INITIAL_COUNT = 3
  USER = "pedroffd"

  def initialize(octokit:)
    @octokit = octokit
  end

  def generate
    participants = Hash.new(0)
    current_contributors = Hash.new(0)
    current_words_added = INITIAL_COUNT
    total_clouds = CloudTypes::CLOUDLABELS.length
    total_words_added = INITIAL_COUNT * total_clouds

    octokit.issues.each do |issue|
      participants[issue.user.login] += 1
      if issue.title.split('|')[1] != SHUFFLECLOUD && issue.labels.any? { |label| CloudTypes::CLOUDLABELS.include?(label.name) }
        total_words_added += 1
        if issue.labels.any? { |label| label.name == CloudTypes::CLOUDLABELS.last }
          current_words_added += 1
          current_contributors[issue.user.login] += 1
        end
      end
    end

    markdown = <<~HTML
# Hi I'm Jessica 👋

[![Linkedin Badge](https://img.shields.io/badge/pedro-souza-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/pedro-henrique-souza/)](https://www.linkedin.com/in/pedro-henrique-souza/)
[![Instagram Badge](https://img.shields.io/badge/-@o_pedro_souza-purple?style=flat&logo=instagram&logoColor=white&link=https://instagram.com/o_pedro_souza/)](https://instagram.com/o_pedro_souza)
[![Gmail Badge](https://img.shields.io/badge/-pedro-c14438?style=flat&logo=Gmail&logoColor=white&link=mailto:pedro.alcarin@gmail.com)](mailto:pedro.alcarin@gmail.com)


Welcome to my profile! I'm a software engineer/project manager and a cook in my spare time. Currently I'm working as Project Manager at @popstand but in my spared I love to code and learn cool stuff

## Join the Community Word Cloud :cloud: :pencil2:

![](https://img.shields.io/badge/Words%20Added-#{total_words_added}-brightgreen?labelColor=7D898B)
![](https://img.shields.io/badge/Word%20Clouds%20Created-#{total_clouds}-48D6FF?labelColor=7D898B)
![](https://img.shields.io/badge/Total%20Participants-#{participants.size}-AC6EFF?labelColor=7D898B)

### :thought_balloon: [Add a word](https://github.com/pedroffd/pedroffd/issues/new?template=addword.md&title=wordcloud%7C#{ADDWORD}%7C%3CINSERT-WORD%3E) to see the word cloud update in real time :rocket:

A new word cloud will be automatically generated when you [add your own word](https://github.com/pedroffd/pedroffd/issues/new?template=addword.md&title=wordcloud%7C#{ADDWORD}%7C%3CINSERT-WORD%3E). The prompt will change frequently, so be sure to come back and check it out :relaxed:

:star2: Don't like the arrangement of the current word cloud? [Regenerate it](https://github.com/pedroffd/pedroffd/issues/new?template=shufflecloud.md&title=wordcloud%7C#{SHUFFLECLOUD}) :game_die:

<div align="center">

## #{CloudTypes::CLOUDPROMPTS.last}

<img src="#{WORD_CLOUD_URL}" alt="WordCloud" width="100%">

![Word Cloud Words Badge](https://img.shields.io/badge/Words%20in%20this%20Cloud-#{current_words_added}-informational?labelColor=7D898B)
![Word Cloud Contributors Badge](https://img.shields.io/badge/Contributors%20this%20Cloud-#{current_contributors.size}-blueviolet?labelColor=7D898B)

    HTML

    # TODO: [![Github Badge](https://img.shields.io/badge/-@username-24292e?style=flat&logo=Github&logoColor=white&link=https://github.com/username)](https://github.com/username)

    current_contributors.each do |username, count|
      markdown.concat("[![Github Badge](https://img.shields.io/badge/-@#{format_username(username)}-24292e?style=flat&logo=Github&logoColor=white&link=https://github.com/#{username})](https://github.com/#{username}) ")
    end

    markdown.concat("\n\n Check out the [previous word cloud](#{previous_cloud_url}) to see our community's **#{CloudTypes::CLOUDPROMPTS[-2]}**")

    markdown.concat("</div>")

    markdown.concat("\n\n ### Need inspiration for your own README? Check out [How to Stand out on GitHub using Profile READMEs](https://medium.com/better-programming/how-to-stand-out-on-github-with-profile-readmes-dfd2102a3490?source=friends_link&sk=61df9c4b63b329ad95528b8d7c00061f)")
  end

  private

  def format_username(name)
    name.gsub('-', '--')
  end

  def previous_cloud_url
    url_end = CloudTypes::CLOUDPROMPTS[-2].gsub(' ', '-').gsub(':', '').gsub('?', '').downcase
    "https://github.com/pedroffd/pedroffd/blob/master/previous_clouds/previous_clouds.md##{url_end}"
  end

  attr_reader :octokit
end
