# frozen_string_literal: true

require 'test_helper'

class ApplicationMarkdownTest < ActiveSupport::TestCase
  test 'une image pointant vers une vidéo YouTube est intégrée en lecteur vidéo' do
    html = rendre('![Présentation](https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42)')

    assert_includes html, '<iframe'
    assert_includes html, 'src="https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"'
  end

  test 'une image hors YouTube est affichée comme une image' do
    html = rendre('![Logo](https://exemple.fr/logo.png)')

    assert_includes html, '<img'
    assert_includes html, 'src="https://exemple.fr/logo.png"'
    assert_not_includes html, '<iframe'
  end

  private

  def rendre(markdown)
    ApplicationMarkdown.new.renderer.render(markdown)
  end
end
