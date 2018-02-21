require "net/http"
require 'open-uri'
require 'nokogiri'

namespace :proposals do
  desc "Find proposals with documents returning a 404"
  task documents_404: :environment do
    proposals_with_404_documents = []
    proposals_with_no_documents = []
    proposals_with_200_documents = []

    proposals = Proposal.all
    proposals.each do |proposal|
      puts proposal.id

      begin
        proposal_url = "https://decide.madrid.es/proposals/#{proposal.id}"
        doc = Nokogiri::HTML(open(proposal_url))
        documents = doc.css('div#tab-documents a').map { |link| link['href'] }

        if documents.any?
          documents.each do |document|
            url = URI.parse("https://decide.madrid.es" + document)
            req = Net::HTTP.new(url.host, url.port)
            req.use_ssl = true
            res = req.request_head(url.path)
            if res.code == "404"
              proposals_with_404_documents << proposal.id
            else
              proposals_with_200_documents << proposal.id
            end
          end
        else
          proposals_with_no_documents << proposal.id
        end
      rescue
        puts "problem with proposal: #{proposal.id}"
      end

    end

    puts "proposals_with_no_documents: #{proposals_with_no_documents.count}"
    puts proposals_with_no_documents

    puts "proposals_with_200_documents: #{proposals_with_200_documents.count}"
    puts proposals_with_200_documents

    puts "proposals_with_404_documents: #{proposals_with_404_documents.count}"
    puts proposals_with_404_documents
  end
end