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
- **Standardized Notation**: $X_{\text{Host}}^{\text{Target}}\langle \text{Type} \rangle$ as the universal notation format.

