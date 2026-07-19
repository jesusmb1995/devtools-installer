---
name: coding-preferences
description: Code style guide. C++ focus. Use for write/refactor/review.
---

# Code Style

## C++ Rules

- **Comments**: Use `///`. No `/** */`.
- **No Redundant Comments**: Code self-documenting. No `x=2; // set x`. Avoid redundant comments on test suites or test cases where the name is already descriptive enough.
- **No Restating Language Rules**: Never write a comment whose only content is a restatement of a well-known C++ language rule the reader is presumed to know — destruction order (members destroyed in reverse declaration order), RAII, virtual dispatch, NRVO/copy elision, integer promotion, etc. Comments should describe *intent or non-obvious constraints*, not language mechanics.
  - Bad: `/// Declared after llmContext_ so it is destroyed first (captures llama_context*).`
    - Why: the destruction-order rule is a language guarantee. The reader can derive it from declaration order alone. Comment adds noise, drifts when refactored.
  - Good (when nothing useful to say): drop the comment entirely.
  - Good (when there *is* a non-obvious trap): `/// Captures this. Caller must outlive the registered callback; cancellation runs on a background thread.` — explains a real lifetime/threading hazard the reader cannot derive from `std::function<void()>` alone.
  - Rule of thumb: if the comment would still be true after substituting any other type for the field, it is probably restating language rules and should go.
- **Named Constants over Inline Param Comments**: Never label call-site arguments with `/*name=*/literal`. Hoist to a `constexpr` local with a real name. The constant gets a type, gets reused in assertions, and stops `/* */` comment style from creeping in.
  - Good: `constexpr int32_t batchCapacity = 4; LlamaBatch batch(batchCapacity, 0, batchSize);`
  - Bad: `LlamaBatch batch(/*n_tokens=*/4, /*embd=*/0, /*n_seq_max=*/4);`
- **Public API Comments = Contract, Not Implementation**: Doc comments on public methods/classes/fields describe what the caller can rely on (preconditions, postconditions, observable behavior, error modes). Do not expose internal arithmetic, loop structure, member names, or formulas the caller cannot act on. If a caller cannot use the detail to make a decision, drop it.
  - Good: `/// Fill batch with tokens. Never writes past batch.capacity(); if the batch cannot hold at least one token per active sequence, returns chunkSize == 0 and leaves the batch empty.`
  - Bad: `/// chunkSize is clamped so chunkSize * numActiveSequences <= batch.capacity().` (exposes the formula; caller cannot use this to decide anything they could not decide from the contract above)
  - Implementation details belong in `.cpp` next to the code they describe, or in a `/// @internal` block, never on the public surface.
- **Bool Return**: Assign condition to bool, check, return bool. Avoid early return. Mark the bool `const` (see *Local `const` for single-assignment locals*).
  - Good: `const bool ok = check(); if (ok) { do(); } return ok;`
  - Bad: `if (!check()) return false; do(); return true;`
- **Inline single-use checks; only name when reused**: A named `const bool` is justified when the bool is read more than once (e.g. checked then returned, checked in two branches, logged + checked) *or* when the expression is opaque enough that a name documents intent. When a bool is read exactly once and the predicate is self-explanatory, inline it in the `if` — naming a one-shot local just to label `if (!x)` adds a line and a noun without buying anything. Same applies to other one-shot non-bool locals used only as an `if`/`switch` condition.
  - Good (inline, single use, predicate is self-describing): `if (!std::ranges::all_of(done, std::identity{})) { throw …; }`
  - Good (named, used twice): `const bool ok = check(); if (ok) { do(); } return ok;`
  - Good (named, opaque expression): `const bool isValid = seqId < slots_.size() && slots_[seqId].has_value() && !slots_[seqId]->finishedGeneration;` — name documents the predicate; inlining would hide it inside an `if`.
  - Bad (named for one-shot self-evident check): `const bool allDone = std::ranges::all_of(done, std::identity{}); if (!allDone) { throw …; }` — the variable name only restates the algorithm; inline.
  - Tie-breaker: if you find yourself reaching for a synonym of the predicate as the variable name (`isValid` for `x.valid()`, `allDone` for `all_of(done, …)`), the name is redundant — inline. If the name describes a *concept* the predicate computes (`hasOverrides`, `quotaExceeded`), keep it.
- **Local `const` for single-assignment locals**: Mark every local that is assigned exactly once and never rebound `const` (or `constexpr` when initialiser is a constant expression). Especially required for the predicate-bool pattern from *Bool Return*, for `const auto` bindings of expressions whose value is only read, and for any local that exists solely to be tested by a following `if` / `throw`. The `const` is information for the reader (and for the optimiser) that the value never changes — drop it only when the variable is genuinely re-assigned later in scope.
  - Good: `const bool ctxValid = a && b && c; if (!ctxValid) { throw …; }`
  - Good: `const auto reqCap = std::min(prompt + nPredict, ceiling);`
  - Bad: `bool ctxValid = a && b && c; if (!ctxValid) { throw …; }` (no later reassignment — should be `const`)
  - Bad: `auto reqCap = std::min(...); use(reqCap);` (single-read, never rebound — should be `const auto`)
- **Modern C++**: Use C++20 ranges/functional over loops when clearer (e.g., `std::views::filter`). Add `namespace views = std::views;` alias in `.cpp` files. Avoid non-standard short aliases.
- **`std::identity` over trivial pass-through lambdas (C++20)**: When an algorithm/range needs a predicate or projection that just returns its argument, pass `std::identity{}` instead of writing `[](T x) { return x; }`. It's a named, transparent, type-agnostic function object — no implicit narrowing in the parameter, no per-call-site copy of the same body, and the intent ("no transformation") is in the name. Same applies to range-adaptor projections (`std::views::transform(std::identity{})` is rare but legitimate).
  - Good: `bool allDone = std::ranges::all_of(flags, std::identity{});`
  - Good: `auto byKey = std::ranges::sort(items, std::less{}, &Item::key);` — projection slot also defaults to `std::identity`, omit when defaulted.
  - Bad: `std::ranges::all_of(flags, [](bool b) { return b; });` (re-implements `std::identity`, can narrow if `T` is wider than `bool`)
  - Bad: `std::ranges::transform(in, out.begin(), [](auto&& x) { return x; });` — use `std::ranges::copy` (intent is copy, not transform).
- **`if`/`switch` Init-Statement (C++17)**: When a variable is declared solely to be tested by the very next `if`/`switch`, fold the declaration into the statement's init-clause so the variable's scope is exactly the branches that need it. Same rule for `for`-range loops with a setup expression. Don't apply this when the variable is reused after the branch — readability beats scope tightening.
  - Good: `if (auto status = call(); status != Ok) { throw Err(toInt(status)); }`
  - Good: `if (const auto it = map.find(k); it != map.end()) { use(it->second); }`
  - Bad: `auto status = call(); if (status != Ok) { throw Err(toInt(status)); }` (status leaks past the if)
  - Bad: `if (auto x = compute(); cond(x)) { a(x); } b(x); /* error: x out of scope */` — keep the plain declaration when `x` is needed afterwards.
- **Enums**: Use small underlying types (e.g., `uint8_t`, `int8_t`) for enums when the range of values is small.
- **Variable Naming**: Use at least three characters for variable names to ensure clarity. Exceptions include loop counters (e.g., `i`, `j`), coordinates (e.g., `x`, `y`), or well-known mathematical symbols.
- **Auto Usage**: Use `auto` whenever the right-hand side already states the type — `static_cast<T>(...)`, `std::make_unique<T>(...)`, `std::make_shared<T>(...)`, named ctor like `T{...}` — regardless of whether `T` is "simple" (`int`, `unsigned`, `size_t`, etc.). Repeating `T` on the LHS is noise and rots when the cast type changes. Also use `auto` for iterators, range-based loops, and other complex inferred types. Avoid `auto` only when the RHS does *not* state the type and the reader cannot infer it from the call (e.g., a function whose return type is not obvious from its name).
  - Good: `const auto ctxTotalTokens = static_cast<unsigned>(llama_n_ctx(ctx));`
  - Good: `auto sched = std::make_unique<ContinuousBatchScheduler>(...);`
  - Bad: `const unsigned ctxTotalTokens = static_cast<unsigned>(llama_n_ctx(ctx));` (duplicates `unsigned`)
  - Bad: `auto x = computeStuff();` (return type not obvious from name)
- **API Status**: Check status/error for low-level API calls (e.g., `vk_` calls).

## Google C++ Style Guide

See [[google_cpp20_guide.md]] for compressed reference covering: headers, scoping, classes, functions, naming, comments, formatting, and C++ features. Use as baseline; project rules in this file take precedence on conflicts (e.g., `///` comments, bool-return pattern).

## Examples (C++)

### Comments
```cpp
/// Calc area
double calculateArea(double r);
```

### Bool Return
```cpp
// Good
const bool isValid = seqId < slots_.size() && slots_[seqId].has_value();
if (isValid) {
  slots_[seqId]->finishedGeneration = true;
}
return isValid;

// Bad
if (seqId >= slots_.size() || !slots_[seqId].has_value()) return false;
slots_[seqId]->finishedGeneration = true;
return true;
```

### Functional (C++20)
```cpp
// Good
auto evens = nums | std::views::filter([](int n){ return n%2==0; });

// Bad
std::vector<int> evens;
for (int n : nums) {
  if (n%2==0) evens.push_back(n);
}
```
