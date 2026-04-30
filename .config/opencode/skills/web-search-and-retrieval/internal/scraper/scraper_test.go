// Copyright 2026 Anders Breindahl. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package scraper

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestNewScraper(t *testing.T) {
	t.Run("default user agent", func(t *testing.T) {
		scraper := NewScraper("")
		if scraper == nil {
			t.Fatal("expected scraper to be non-nil")
		}
	})

	t.Run("custom user agent", func(t *testing.T) {
		customUA := "CustomBot/1.0"
		scraper := NewScraper(customUA)
		if scraper == nil {
			t.Fatal("expected scraper to be non-nil")
		}
	})
}

func TestFetch_Success(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(`<html><body><h1>Test</h1></body></html>`))
		if err != nil {
			t.Fatalf("failed to write response: %v", err)
		}
	}))
	defer testServer.Close()

	scraper := NewScraper("")
	ctx := context.Background()

	result, err := scraper.Fetch(ctx, testServer.URL)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result == "" {
		t.Fatal("expected non-empty markdown result")
	}
}

func TestFetch_InvalidURL(t *testing.T) {
	scraper := NewScraper("")
	ctx := context.Background()

	_, err := scraper.Fetch(ctx, "not-a-valid-url")
	if err == nil {
		t.Fatal("expected error for invalid URL, got nil")
	}
}

func TestFetch_NetworkError(t *testing.T) {
	scraper := NewScraper("")
	ctx := context.Background()

	_, err := scraper.Fetch(ctx, "http://localhost:1")
	if err == nil {
		t.Fatal("expected error for network failure, got nil")
	}
}

func TestFetch_UnsupportedContentType(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(`{"key": "value"}`))
		if err != nil {
			t.Fatalf("failed to write response: %v", err)
		}
	}))
	defer testServer.Close()

	scraper := NewScraper("")
	ctx := context.Background()

	_, err := scraper.Fetch(ctx, testServer.URL)
	if err == nil {
		t.Fatal("expected error for non-HTML content type, got nil")
	}
}

func TestFetch_UserAgent(t *testing.T) {
	var receivedUA string
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedUA = r.UserAgent()
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(`<html><body><h1>Test</h1></body></html>`))
		if err != nil {
			t.Fatalf("failed to write response: %v", err)
		}
	}))
	defer testServer.Close()

	customUA := "TestBot/1.0"
	scraper := NewScraper(customUA)
	ctx := context.Background()

	_, err := scraper.Fetch(ctx, testServer.URL)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if receivedUA != customUA {
		t.Errorf("expected user agent %q, got %q", customUA, receivedUA)
	}
}

func TestFetch_Timeout(t *testing.T) {
	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(2 * time.Second)
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(`<html><body><h1>Test</h1></body></html>`))
		if err != nil {
			t.Fatalf("failed to write response: %v", err)
		}
	}))
	defer testServer.Close()

	scraper := NewScraper("")
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	_, err := scraper.Fetch(ctx, testServer.URL)
	if err == nil {
		t.Fatal("expected timeout error, got nil")
	}
}

func TestConvertToMarkdown_BasicHTML(t *testing.T) {
	tests := []struct {
		name     string
		html     string
		expected string
	}{
		{
			name:     "heading",
			html:     "<h1>Hello World</h1>",
			expected: "# Hello World",
		},
		{
			name:     "paragraph",
			html:     "<p>This is a paragraph.</p>",
			expected: "This is a paragraph.",
		},
		{
			name:     "bold text",
			html:     "<strong>Bold</strong>",
			expected: "**Bold**",
		},
		{
			name:     "italic text",
			html:     "<em>Italic</em>",
			expected: "*Italic*",
		},
		{
			name:     "link",
			html:     `<a href="https://example.com">Link</a>`,
			expected: "[Link](https://example.com)",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := convertToMarkdown(tt.html)
			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}

			if result != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, result)
			}
		})
	}
}

func TestConvertToMarkdown_ComplexHTML(t *testing.T) {
	html := `
	<html>
		<body>
			<h1>Main Title</h1>
			<p>This is a <strong>paragraph</strong> with <em>formatting</em>.</p>
			<ul>
				<li>Item 1</li>
				<li>Item 2</li>
			</ul>
			<p>Visit <a href="https://example.com">our site</a> for more.</p>
		</body>
	</html>
	`

	result, err := convertToMarkdown(html)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result == "" {
		t.Fatal("expected non-empty markdown result")
	}

	// Check for key markdown elements
	expectedElements := []string{"# Main Title", "**paragraph**", "*formatting*", "- Item 1", "[our site](https://example.com)"}
	for _, element := range expectedElements {
		if !contains(result, element) {
			t.Errorf("expected result to contain %q, got %q", element, result)
		}
	}
}

func TestConvertToMarkdown_EmptyHTML(t *testing.T) {
	tests := []struct {
		name string
		html string
	}{
		{"empty string", ""},
		{"whitespace only", "   "},
		{"empty tags", "<html></html>"},
		{"body only", "<body></body>"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := convertToMarkdown(tt.html)
			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}

			// Empty HTML should result in empty or whitespace-only markdown
			if trimSpace(result) != "" {
				t.Errorf("expected empty result, got %q", result)
			}
		})
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > len(substr) && findSubstring(s, substr))
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

func trimSpace(s string) string {
	start := 0
	end := len(s)
	for start < end && (s[start] == ' ' || s[start] == '\n' || s[start] == '\t' || s[start] == '\r') {
		start++
	}
	for end > start && (s[end-1] == ' ' || s[end-1] == '\n' || s[end-1] == '\t' || s[end-1] == '\r') {
		end--
	}
	return s[start:end]
}

func TestDebugLogging(t *testing.T) {
	os.Setenv("DEBUG", "DEBUG")
	defer os.Unsetenv("DEBUG")

	var logOutput strings.Builder
	var mu sync.Mutex

	DebugLogger = func(format string, args ...interface{}) {
		mu.Lock()
		defer mu.Unlock()
		logOutput.WriteString(fmt.Sprintf(format+"\n", args...))
	}

	testServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		_, err := w.Write([]byte(`<html><body><h1>Test</h1></body></html>`))
		if err != nil {
			t.Fatalf("failed to write response: %v", err)
		}
	}))
	defer testServer.Close()

	scraper := NewScraper("")
	ctx := context.Background()

	_, err := scraper.Fetch(ctx, testServer.URL)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	mu.Lock()
	output := logOutput.String()
	mu.Unlock()

	if output == "" {
		t.Fatal("expected debug output, got empty string")
	}

	if !strings.Contains(output, "[DEBUG] Request:") {
		t.Errorf("expected [DEBUG] Request: in output, got:\n%s", output)
	}

	if !strings.Contains(output, "[DEBUG] Response:") {
		t.Errorf("expected [DEBUG] Response: in output, got:\n%s", output)
	}
}
