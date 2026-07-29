// ╔══════════════════════════════════════════════════════════════════════════════════╗
// ║  🦀 MODULE NAME — ASH DOTFILES v5.0 OMEGA                                      ║
// ║  Description  : Brief description of what this module does                     ║
// ║  Author       : ash                                                             ║
// ║  Created      : 2024-01-01                                                      ║
// ║  Edition      : 2021                                                            ║
// ╚══════════════════════════════════════════════════════════════════════════════════╝
//!
//! # Module Name
//!
//! Brief description of what this module provides.
//!
//! ## Overview
//!
//! Longer description explaining the module's purpose, design decisions,
//! and how it fits into the larger codebase.
//!
//! ## Examples
//!
//! ```rust
//! use module_name::StructName;
//!
//! let obj = StructName::new("example");
//! let result = obj.process()?;
//! println!("{result}");
//! ```
//!
//! ## Feature flags
//!
//! - `feature-name`: Enables optional functionality (default: disabled)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚙️  CRATE ATTRIBUTES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![deny(missing_docs)]
#![allow(clippy::module_name_repetitions)]
#![allow(clippy::missing_errors_doc)]

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📦 IMPORTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

use std::{
    collections::HashMap,
    fmt,
    path::{Path, PathBuf},
    sync::{Arc, Mutex},
};

use serde::{Deserialize, Serialize};
use thiserror::Error;
use tracing::{debug, error, info, instrument, warn};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🚨 ERROR TYPE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// All errors that can be produced by this module.
#[derive(Debug, Error)]
pub enum Error {
    /// Input file could not be found or read.
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    /// Serialisation / deserialisation failure.
    #[error("serialisation error: {0}")]
    Serde(#[from] serde_json::Error),

    /// A required value was absent.
    #[error("missing required field: {field}")]
    MissingField {
        /// Name of the missing field.
        field: String,
    },

    /// An invariant was violated.
    #[error("invalid state: {message}")]
    InvalidState {
        /// Human-readable description of the problem.
        message: String,
    },
}

/// Convenient Result alias using this module's [`Error`] type.
pub type Result<T, E = Error> = std::result::Result<T, E>;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚙️  CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Configuration for [`StructName`].
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case", deny_unknown_fields)]
pub struct Config {
    /// Human-readable name.
    pub name: String,

    /// Maximum number of retries.
    #[serde(default = "Config::default_max_retries")]
    pub max_retries: u32,

    /// Optional output path.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output_path: Option<PathBuf>,

    /// Arbitrary key-value metadata.
    #[serde(default)]
    pub metadata: HashMap<String, String>,
}

impl Config {
    /// Default value for [`Config::max_retries`].
    #[must_use]
    const fn default_max_retries() -> u32 {
        3
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            name:        String::new(),
            max_retries: Self::default_max_retries(),
            output_path: None,
            metadata:    HashMap::new(),
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏗️  MAIN STRUCT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Primary struct of this module.
///
/// # Examples
///
/// ```rust
/// # use crate::StructName;
/// let obj = StructName::new("my-instance");
/// assert_eq!(obj.name(), "my-instance");
/// ```
#[derive(Debug, Clone)]
pub struct StructName {
    config: Config,
    state:  Arc<Mutex<State>>,
}

/// Internal mutable state.
#[derive(Debug, Default)]
struct State {
    processed: u64,
    errors:    u64,
}

impl StructName {
    // ── Constructors ──────────────────────────────────────────────────────────────

    /// Create a new instance with just a name and default configuration.
    #[must_use]
    pub fn new(name: impl Into<String>) -> Self {
        let config = Config {
            name: name.into(),
            ..Config::default()
        };
        Self::with_config(config)
    }

    /// Create a new instance from a complete [`Config`].
    #[must_use]
    pub fn with_config(config: Config) -> Self {
        debug!(name = %config.name, "Creating StructName");
        Self {
            config,
            state: Arc::new(Mutex::new(State::default())),
        }
    }

    /// Load configuration from a JSON file and construct an instance.
    ///
    /// # Errors
    ///
    /// Returns [`Error::Io`] if the file cannot be read, or
    /// [`Error::Serde`] if the JSON is malformed.
    pub fn from_file(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        debug!(path = %path.display(), "Loading config from file");
        let bytes  = std::fs::read(path)?;
        let config = serde_json::from_slice(&bytes)?;
        Ok(Self::with_config(config))
    }

    // ── Accessors ─────────────────────────────────────────────────────────────────

    /// Returns the instance's name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.config.name
    }

    /// Returns a reference to the full configuration.
    #[must_use]
    pub fn config(&self) -> &Config {
        &self.config
    }

    /// Returns the number of successfully processed items.
    ///
    /// # Panics
    ///
    /// Panics if the internal mutex is poisoned.
    #[must_use]
    pub fn processed_count(&self) -> u64 {
        self.state.lock().expect("mutex poisoned").processed
    }

    // ── Core operations ───────────────────────────────────────────────────────────

    /// Process a single item.
    ///
    /// # Errors
    ///
    /// Returns [`Error::InvalidState`] when processing fails after all
    /// configured retries are exhausted.
    #[instrument(skip(self), fields(name = %self.name()))]
    pub fn process(&self, input: &str) -> Result<String> {
        let mut attempt = 0u32;

        loop {
            match self.try_process(input) {
                Ok(output) => {
                    self.state.lock().expect("mutex poisoned").processed += 1;
                    info!("Processed successfully");
                    return Ok(output);
                }
                Err(e) if attempt < self.config.max_retries => {
                    attempt += 1;
                    warn!(attempt, error = %e, "Processing failed, retrying");
                }
                Err(e) => {
                    self.state.lock().expect("mutex poisoned").errors += 1;
                    error!(error = %e, "Processing failed after all retries");
                    return Err(Error::InvalidState {
                        message: format!("processing failed after {attempt} retries: {e}"),
                    });
                }
            }
        }
    }

    /// Serialise the current configuration to JSON.
    ///
    /// # Errors
    ///
    /// Returns [`Error::Serde`] on serialisation failure (should not happen
    /// in practice).
    pub fn to_json(&self) -> Result<String> {
        Ok(serde_json::to_string_pretty(&self.config)?)
    }

    // ── Private helpers ───────────────────────────────────────────────────────────

    fn try_process(&self, input: &str) -> Result<String> {
        // Placeholder: replace with actual processing logic
        Ok(format!("[{}] {}", self.config.name, input))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎭 TRAIT IMPLEMENTATIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

impl fmt::Display for StructName {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "StructName({})", self.config.name)
    }
}

impl TryFrom<Config> for StructName {
    type Error = Error;

    fn try_from(config: Config) -> Result<Self> {
        if config.name.is_empty() {
            return Err(Error::MissingField {
                field: "name".into(),
            });
        }
        Ok(Self::with_config(config))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧪 TESTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#[cfg(test)]
mod tests {
    use super::*;

    fn make_sut(name: &str) -> StructName {
        StructName::new(name)
    }

    #[test]
    fn test_new_sets_name() {
        let sut = make_sut("test-instance");
        assert_eq!(sut.name(), "test-instance");
    }

    #[test]
    fn test_process_increments_counter() {
        let sut = make_sut("counter-test");
        assert_eq!(sut.processed_count(), 0);

        sut.process("hello").expect("process should succeed");
        assert_eq!(sut.processed_count(), 1);
    }

    #[test]
    fn test_try_from_config_fails_on_empty_name() {
        let config = Config::default(); // name = ""
        let result = StructName::try_from(config);
        assert!(
            matches!(result, Err(Error::MissingField { .. })),
            "expected MissingField error, got: {result:?}",
        );
    }

    #[test]
    fn test_display_format() {
        let sut = make_sut("display-test");
        assert_eq!(sut.to_string(), "StructName(display-test)");
    }

    #[test]
    fn test_config_serialisation_roundtrip() {
        let original = Config {
            name: "roundtrip".into(),
            max_retries: 5,
            ..Config::default()
        };
        let sut  = StructName::with_config(original.clone());
        let json = sut.to_json().expect("serialisation should succeed");
        let back: Config =
            serde_json::from_str(&json).expect("deserialisation should succeed");
        assert_eq!(back, original);
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🚀 BINARY ENTRY POINT (only compiled when this is a binary crate)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

fn main() -> Result<()> {
    // Initialise structured logging
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let obj = StructName::new("main-instance");
    let result = obj.process("hello, world")?;
    println!("{result}");

    Ok(())
}