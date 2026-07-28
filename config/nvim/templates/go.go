// ╔══════════════════════════════════════════════════════════════════════════════════╗
// ║  🐹 PACKAGE NAME — ASH DOTFILES v5.0 OMEGA                                     ║
// ║  Description  : Brief description of what this package does                    ║
// ║  Author       : ash                                                             ║
// ║  Created      : 2024-01-01                                                      ║
// ╚══════════════════════════════════════════════════════════════════════════════════╝

// Package packagename provides brief description of the package.
//
// Longer description explaining the package's purpose and how it should be used.
// Include important design decisions and any caveats.
//
// # Overview
//
// The package is structured as follows:
//   - TypeName: Core type (see [TypeName])
//   - Config:   Configuration options (see [Config])
//   - Error:    Error definitions (see [Error])
//
// # Examples
//
// Basic usage:
//
//	obj, err := packagename.New(packagename.Config{Name: "example"})
//	if err != nil {
//	    log.Fatal(err)
//	}
//	result, err := obj.Process(ctx, "input")
//	if err != nil {
//	    log.Fatal(err)
//	}
//	fmt.Println(result)
package packagename

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 IMPORTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"sync"
	"time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔢 CONSTANTS & VARIABLES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const (
	// DefaultTimeout is the default operation timeout.
	DefaultTimeout = 30 * time.Second

	// DefaultMaxRetries is the default number of retry attempts.
	DefaultMaxRetries = 3
)

// Sentinel errors for use with errors.Is.
var (
	// ErrNotFound is returned when a requested resource cannot be located.
	ErrNotFound = errors.New("not found")

	// ErrInvalidInput is returned when the caller provides bad input.
	ErrInvalidInput = errors.New("invalid input")

	// ErrTimeout is returned when an operation exceeds its deadline.
	ErrTimeout = errors.New("operation timed out")
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚙️  CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Config holds configuration for [TypeName].
type Config struct {
	// Name is the human-readable identifier (required).
	Name string

	// Timeout limits the duration of a single operation.
	// Defaults to [DefaultTimeout] when zero.
	Timeout time.Duration

	// MaxRetries controls how many times a failing operation is retried.
	// Defaults to [DefaultMaxRetries] when zero.
	MaxRetries int

	// Logger is the structured logger to use.
	// Defaults to the default slog handler when nil.
	Logger *slog.Logger

	// Output is where results are written.
	// Defaults to [os.Stdout] when nil.
	Output io.Writer
}

// validate checks that the configuration is internally consistent.
func (c *Config) validate() error {
	if c.Name == "" {
		return fmt.Errorf("%w: Name must not be empty", ErrInvalidInput)
	}
	return nil
}

// withDefaults fills in zero-value fields with sensible defaults.
func (c *Config) withDefaults() Config {
	out := *c
	if out.Timeout == 0 {
		out.Timeout = DefaultTimeout
	}
	if out.MaxRetries == 0 {
		out.MaxRetries = DefaultMaxRetries
	}
	if out.Logger == nil {
		out.Logger = slog.Default()
	}
	if out.Output == nil {
		out.Output = os.Stdout
	}
	return out
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏗️  CORE TYPE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// TypeName is the primary exported type of this package.
// It is safe for concurrent use by multiple goroutines.
type TypeName struct {
	cfg    Config
	log    *slog.Logger
	mu     sync.RWMutex
	stats  stats
}

// stats holds internal metrics.
type stats struct {
	processed uint64
	errors    uint64
}

// New creates a new [TypeName] with the supplied configuration.
// It returns an error if the configuration is invalid.
//
// Example:
//
//	obj, err := packagename.New(packagename.Config{Name: "example"})
func New(cfg Config) (*TypeName, error) {
	cfg = cfg.withDefaults()
	if err := cfg.validate(); err != nil {
		return nil, fmt.Errorf("packagename.New: %w", err)
	}
	t := &TypeName{
		cfg: cfg,
		log: cfg.Logger.With(slog.String("component", "TypeName"),
			slog.String("name", cfg.Name)),
	}
	t.log.Debug("created")
	return t, nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔓 ACCESSORS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Name returns the configured name.
func (t *TypeName) Name() string { return t.cfg.Name }

// Processed returns the total number of successfully processed items.
func (t *TypeName) Processed() uint64 {
	t.mu.RLock()
	defer t.mu.RUnlock()
	return t.stats.processed
}

// Errors returns the total number of processing errors.
func (t *TypeName) Errors() uint64 {
	t.mu.RLock()
	defer t.mu.RUnlock()
	return t.stats.errors
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🚀 CORE OPERATIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Process handles a single input string and returns the result.
// It respects the context deadline and retries transient failures up to
// Config.MaxRetries times.
//
// Errors:
//   - [ErrInvalidInput] when input is empty.
//   - [ErrTimeout] when the context deadline is exceeded.
//   - Wrapped underlying errors for all other failures.
func (t *TypeName) Process(ctx context.Context, input string) (string, error) {
	if input == "" {
		return "", fmt.Errorf("Process: %w: input must not be empty", ErrInvalidInput)
	}

	log := t.log.With(slog.String("input_len", fmt.Sprintf("%d", len(input))))
	log.Debug("processing")

	var (
		result string
		err    error
	)

	for attempt := range t.cfg.MaxRetries + 1 {
		if err = ctx.Err(); err != nil {
			return "", fmt.Errorf("Process: %w", ErrTimeout)
		}

		result, err = t.doProcess(ctx, input)
		if err == nil {
			break
		}

		if attempt < t.cfg.MaxRetries {
			log.Warn("processing failed, retrying",
				slog.Int("attempt", attempt+1),
				slog.String("error", err.Error()))
		}
	}

	t.mu.Lock()
	if err != nil {
		t.stats.errors++
		t.mu.Unlock()
		return "", fmt.Errorf("Process: %w", err)
	}
	t.stats.processed++
	t.mu.Unlock()

	log.Info("processed successfully")
	return result, nil
}

// doProcess is the internal, non-retrying processing implementation.
func (t *TypeName) doProcess(_ context.Context, input string) (string, error) {
	// TODO: Replace with actual processing logic.
	return fmt.Sprintf("[%s] %s", t.cfg.Name, input), nil
}

// String returns a human-readable representation.
func (t *TypeName) String() string {
	return fmt.Sprintf("TypeName{name: %q}", t.cfg.Name)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧪 EXAMPLE (godoc)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ExampleNew demonstrates how to create and use a TypeName.
func ExampleNew() {
	obj, err := New(Config{Name: "example"})
	if err != nil {
		panic(err)
	}

	result, err := obj.Process(context.Background(), "hello")
	if err != nil {
		panic(err)
	}

	fmt.Println(result)
	// Output: [example] hello
}