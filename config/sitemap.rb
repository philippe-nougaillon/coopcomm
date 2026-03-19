require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://demo.coopcomm.fr'
SitemapGenerator::Sitemap.create do
  add '/mentions_legales', :changefreq => 'weekly'
  add '/wiki', :changefreq => 'weekly'
end
# SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks