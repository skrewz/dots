// Copyright 2026 Anders Breindahl. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package search

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestBuildSearchURL(t *testing.T) {
	searcher := NewSearcher(nil)
	tests := []struct {
		name     string
		query    string
		expected string
	}{
		{
			name:     "basic query",
			query:    "golang tutorial",
			expected: "https://html.duckduckgo.com/html/?q=golang+tutorial",
		},
		{
			name:     "query with special characters",
			query:    "what is Go?",
			expected: "https://html.duckduckgo.com/html/?q=what+is+Go%3F",
		},
		{
			name:     "query with spaces",
			query:    "hello world",
			expected: "https://html.duckduckgo.com/html/?q=hello+world",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := searcher.buildSearchURL(tt.query)
			if result != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, result)
			}
		})
	}
}

func TestParseSearchResults_BasicResults(t *testing.T) {
	html := `
	<html>
		<body>
			<div class="result">
				<h2><a class="result__a" href="https://example.com/1">First Result</a></h2>
				<a class="result__snippet">This is the first result context.</a>
			</div>
			<div class="result">
				<h2><a class="result__a" href="https://example.com/2">Second Result</a></h2>
				<a class="result__snippet">This is the second result context.</a>
			</div>
		</body>
	</html>
	`

	results, err := parseSearchResults(html)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(results) != 2 {
		t.Fatalf("expected 2 results, got %d", len(results))
	}

	if results[0].Title != "First Result" {
		t.Errorf("expected title %q, got %q", "First Result", results[0].Title)
	}
	if results[0].Context != "This is the first result context." {
		t.Errorf("expected context %q, got %q", "This is the first result context.", results[0].Context)
	}
}

func TestParseSearchResults_NoResults(t *testing.T) {
	html := `<html><body></body></html>`

	results, err := parseSearchResults(html)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(results) != 0 {
		t.Errorf("expected 0 results, got %d", len(results))
	}
}

func TestSearch_Integration(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/html/") {
			w.Header().Set("Content-Type", "text/html")
			w.WriteHeader(http.StatusOK)
			html := `
			<html>
				<body>
					<div class="result">
						<h2><a class="result__a" href="https://example.com/1">Result 1</a></h2>
						<a class="result__snippet">Context for result 1.</a>
					</div>
					<div class="result">
						<h2><a class="result__a" href="https://example.com/2">Result 2</a></h2>
						<a class="result__snippet">Context for result 2.</a>
					</div>
				</body>
			</html>
			`
			_, err := w.Write([]byte(html))
			if err != nil {
				t.Fatalf("failed to write response: %v", err)
			}
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer testServer.Close()

	searcher := newTestSearcher(testServer.URL, nil)
	ctx := context.Background()

	results, err := searcher.Search(ctx, "test query")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(results) != 2 {
		t.Fatalf("expected 2 results, got %d", len(results))
	}

	if results[0].Title != "Result 1" {
		t.Errorf("expected title %q, got %q", "Result 1", results[0].Title)
	}
	if results[0].Context != "Context for result 1." {
		t.Errorf("expected context %q, got %q", "Context for result 1.", results[0].Context)
	}
}

func TestSearch_ErrorHandling(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/html/") {
			w.WriteHeader(http.StatusInternalServerError)
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer testServer.Close()

	searcher := newTestSearcher(testServer.URL, nil)
	ctx := context.Background()

	_, err := searcher.Search(ctx, "test query")
	if err == nil {
		t.Fatal("expected error for server failure, got nil")
	}
}

func TestSearch_EmptyQuery(t *testing.T) {
	searcher := NewSearcher(nil)
	ctx := context.Background()

	_, err := searcher.Search(ctx, "")
	if err == nil {
		t.Fatal("expected error for empty query, got nil")
	}
}

func TestSearchResult_FormatMarkdown(t *testing.T) {
	results := []SearchResult{
		{
			Title:   "First Result",
			URL:     "https://example.com/1",
			Context: "This is the context for the first result.",
		},
		{
			Title:   "Second Result",
			URL:     "https://example.com/2",
			Context: "This is the context for the second result.",
		},
	}

	expected := `## [First Result](https://example.com/1)
This is the context for the first result.

## [Second Result](https://example.com/2)
This is the context for the second result.
`

	markdown := FormatResultsMarkdown(results)
	if markdown != expected {
		t.Errorf("expected:\n%s\ngot:\n%s", expected, markdown)
	}
}

func TestSearchResult_FormatMarkdown_Empty(t *testing.T) {
	results := []SearchResult{}

	markdown := FormatResultsMarkdown(results)
	if markdown != "No results found." {
		t.Errorf("expected 'No results found.', got %q", markdown)
	}
}

func TestParseSearchResults_AdjacentTextNodes(t *testing.T) {
	html := `
	<html>
		<body>
			<div class="result">
				<h2><a class="result__a" href="https://go.dev/blog/pipelines">Go Concurrency Patterns</a></h2>
				<a class="result__snippet">Learn how to construct streaming data pipelines with <span class="highlight">Go's</span> <span class="highlight">concurrency primitives</span> and deal with failures cleanly.</a>
			</div>
		</body>
	</html>
	`

	results, err := parseSearchResults(html)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(results) != 1 {
		t.Fatalf("expected 1 result, got %d", len(results))
	}

	expectedContext := "Learn how to construct streaming data pipelines with Go's concurrency primitives and deal with failures cleanly."
	if results[0].Context != expectedContext {
		t.Errorf("expected context %q, got %q", expectedContext, results[0].Context)
	}
}

func TestParseSearchResults_MultipleAdjacentTextNodes(t *testing.T) {
	html := `
	<html>
		<body>
			<div class="result">
				<h2><a class="result__a" href="https://example.com">Example</a></h2>
				<a class="result__snippet"><span>Word1</span> <span>Word2</span> <span>Word3</span></a>
			</div>
		</body>
	</html>
	`

	results, err := parseSearchResults(html)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(results) != 1 {
		t.Fatalf("expected 1 result, got %d", len(results))
	}

	if results[0].Context != "Word1 Word2 Word3" {
		t.Errorf("expected context %q, got %q", "Word1 Word2 Word3", results[0].Context)
	}
}

func TestFormatResultsMarkdown_NoSpacesInContext(t *testing.T) {
	results := []SearchResult{
		{
			Title:   "Test",
			URL:     "https://example.com",
			Context: "Go'sconcurrencyprimitives",
		},
	}

	markdown := FormatResultsMarkdown(results)
	// The markdown itself just passes through the context,
	// so we test that FormatResultsMarkdown doesn't corrupt spacing.
	// The real fix is in getTextContent / parseSearchResults.
	if !strings.Contains(markdown, "Go'sconcurrencyprimitives") {
		t.Errorf("expected markdown to contain unmodified context")
	}
}
