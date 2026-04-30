// Copyright 2026 Anders Breindahl. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package search

import (
	"context"
	"fmt"
	"net/url"
	"strings"

	"github.com/skrewz/web-search-mcp/internal/scraper"
	"golang.org/x/net/html"
)

type SearchResult struct {
	Title   string
	URL     string
	Context string
}

type Searcher struct {
	scraper *scraper.Scraper
	baseURL string
}

func NewSearcher(scraperImpl *scraper.Scraper) *Searcher {
	if scraperImpl == nil {
		scraperImpl = scraper.NewScraper("")
	}
	return &Searcher{
		scraper: scraperImpl,
		baseURL: "https://html.duckduckgo.com",
	}
}

func newTestSearcher(baseURL string, scraperImpl *scraper.Scraper) *Searcher {
	if scraperImpl == nil {
		scraperImpl = scraper.NewScraper("")
	}
	return &Searcher{
		scraper: scraperImpl,
		baseURL: baseURL,
	}
}

func (s *Searcher) Search(ctx context.Context, query string) ([]SearchResult, error) {
	if strings.TrimSpace(query) == "" {
		return nil, fmt.Errorf("query cannot be empty")
	}

	searchURL := s.buildSearchURL(query)

	htmlContent, err := s.scraper.FetchHTML(ctx, searchURL)
	if err != nil {
		return nil, fmt.Errorf("fetching search results: %w", err)
	}

	results, err := parseSearchResults(htmlContent)
	if err != nil {
		return nil, fmt.Errorf("parsing search results: %w", err)
	}

	return results, nil
}

func (s *Searcher) buildSearchURL(query string) string {
	params := url.Values{}
	params.Set("q", query)
	return s.baseURL + "/html/?" + params.Encode()
}

func parseSearchResults(htmlContent string) ([]SearchResult, error) {
	doc, err := html.Parse(strings.NewReader(htmlContent))
	if err != nil {
		return nil, fmt.Errorf("parsing HTML: %w", err)
	}

	var results []SearchResult

	var walk func(*html.Node, bool)
	walk = func(n *html.Node, inResult bool) {
		if n.Type == html.ElementNode && n.Data == "div" {
			if hasClass(n, "result") && !inResult {
				result := extractResult(n)
				if result.Title != "" || result.URL != "" || result.Context != "" {
					results = append(results, result)
				}
				inResult = true
			}
		}

		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c, inResult)
		}
	}

	walk(doc, false)

	return results, nil
}

func extractResult(node *html.Node) SearchResult {
	var result SearchResult

	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode {
			if n.Data == "a" {
				if hasClass(n, "result__a") {
					result.Title = getTextContent(n)
					for _, attr := range n.Attr {
						if attr.Key == "href" {
							result.URL = attr.Val
							break
						}
					}
				} else if hasClass(n, "result__snippet") {
					result.Context = getTextContent(n)
				}
			}
		}

		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}

	walk(node)

	return result
}

func hasClass(n *html.Node, className string) bool {
	for _, attr := range n.Attr {
		if attr.Key == "class" {
			classes := strings.Fields(attr.Val)
			for _, class := range classes {
				if class == className {
					return true
				}
			}
		}
	}
	return false
}

func getTextContent(n *html.Node) string {
	var text strings.Builder
	var prevEndedWithSpace bool

	var walk func(*html.Node)
	walk = func(node *html.Node) {
		if node.Type == html.TextNode {
			content := strings.TrimSpace(node.Data)
			if content != "" {
				if text.Len() > 0 && !prevEndedWithSpace {
					text.WriteString(" ")
				}
				text.WriteString(content)
				prevEndedWithSpace = len(content) > 0 && content[len(content)-1] == ' '
			}
		}
		for c := node.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}

	walk(n)

	return strings.TrimSpace(text.String())
}

func FormatResultsMarkdown(results []SearchResult) string {
	if len(results) == 0 {
		return "No results found."
	}

	var sb strings.Builder
	for i, result := range results {
		if i > 0 {
			sb.WriteString("\n")
		}
		sb.WriteString(fmt.Sprintf("## [%s](%s)\n", result.Title, result.URL))
		if result.Context != "" {
			sb.WriteString(result.Context)
		}
		sb.WriteString("\n")
	}

	return sb.String()
}
