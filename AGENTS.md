# Project: MDTT (Heterogeneous Multi-stage Dependent Type Theory)

## Architecture Overview
MDTT is a formal framework for metaprogramming and compiler architectures. It explicitly distinguishes between host ($M$) and target ($L$) languages and models the pipeline from source text through AST to executable code.

### Primary Use Cases
- **Multi-stage Modeling**: Formalizing the staging of computation and code specialization.
- **Architecture Verification**: Using Dependent Types (DT) to capture implementation details and ensure mathematical correctness of compiler construction.

### Core Features
- **Heterogeneity**: Separation of execution environments.
- **Duality**: Separation of analyzable AST and safe, opaque Code.

## File Structure
- `README.md`: Main specification and theoretical foundation.
- `MSP.md`: Analysis of Multi-stage Programming concepts and comparison with other tools.

## Technical Decisions
- **Latex for Formalization**: Using LaTeX for all type rules and operators to ensure mathematical precision.
- **Standardized Notation**: $X_{\text{Host}}^{\text{Target}}\langle \text{Type} \rangle$ as syntactic sugar for generic parameters (Host/Target).

## Notation & Convention Rules
1.  **Term vs Type Capitalization**:
    *   **Terms** (values, instances, functions acting as values) must use **lowercase** or **camelCase**.
        *   Example: `compiler`, `interpreter`, `goal`, `source`.
    *   **Types** (definitions, classifiers) must use **PascalCase** (Capitalized).
        *   Example: `Compiler`, `Interpreter`, `Int`, `Exp`.
2.  **Clarifying Type Aliases**:
    *   Avoid vague descriptors like "logical type" when explaining type aliases (e.g., `Compiler<S,T>`).
    *   Instead, explicitly state the underlying type expansion (e.g., "which expands to $𝒜^S \to 𝒞^T$") or cite the specific definition section.
3.  **Math Rendering Compatibility**:
    *   To ensure correct rendering on GitHub, **avoid** using LaTeX style commands like `\mathcal{L}` which may not render consistently.
    *   **Prefer Unicode** mathematical alphanumeric symbols (e.g., $𝒜, ℬ, 𝒞, ℒ, 𝒫$) instead.
    *   **Spacing**: Ensure there is a space between LaTeX inline math delimiters (`$`) and any adjacent non-ASCII/Unicode characters (e.g., Chinese characters).
        *   Bad: `比如$x$是`
        *   Good: `比如 $x$ 是`
4.  **Consistency**:
    *   Maintain strict consistency in type definitions and notation.
    *   The same object must always appear with the same number of type parameters and identical notation structure throughout the document.

