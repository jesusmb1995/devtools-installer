# Google C++ Style Guide — Compressed

> Source: https://google.github.io/styleguide/cppguide.html
> Style: caveman-compressed. All substance kept.

---

## Goals

Rules must earn their weight. Optimize for **readers not writers**. Consistency > personal preference. Avoid surprising/dangerous constructs. Scale matters.

---

## Headers

- Every header self-contained. Header guard: `PROJECT_PATH_FILE_H_`.
- **Include what you use.** No relying on transitive includes.
- **No forward declarations** — include instead. Forward decls hide deps, break APIs.
- Include order (blank line between groups):
  1. Related `.h`
  2. C system headers
  3. C++ stdlib
  4. Other libs
  5. Project headers
- Inline functions: only if ≤10 lines. Longer → `.cc`.

---

## Scoping

- **Namespaces**: unique names based on project. No `using namespace`. No declarations in `std::`.
- **Internal linkage**: unnamed namespace or `static` in `.cc` only. Never in `.h`.
- **Locals**: narrowest scope possible. Initialize at declaration.
- **Static/global objects**: must be trivially destructible. No dynamic init for non-local statics. Use `constexpr`/`constinit`.
- **`thread_local`**: non-function-scope must be `constinit` + compile-time init.

---

## Classes

- **Constructors**: no virtual calls, no fallible work. Use factory functions or `Init()` if needed.
- **Implicit conversions**: mark `explicit` on single-arg ctors and conversion operators.
- **Copy/move**: explicitly declare or `= delete` in public section. Never leave implicit.
- **`struct` vs `class`**: `struct` = passive data, public fields, no invariants. `class` = everything else.
- **Inheritance**: prefer composition. Public inheritance only. No multiple implementation inheritance. Use `override`/`final`, never `virtual` on overrides.
- **Operator overloading**: only when obvious + consistent with builtins. Non-member for binary ops. Never overload `&&`, `||`, `,`, unary `&`, user-defined literals.
- **Access control**: data members `private` (except constants). Order: `public` → `protected` → `private`.
- **Declaration order within section**: types/aliases → static constants → factories → ctors/assign → dtor → methods → data.

---

## Functions

- **Outputs**: prefer return values over output params. Use `std::optional` for nullable. Non-const pointer for optional output param.
- **Length**: ~40 lines max. Split complex functions.
- **Overloading**: only when call is unambiguous without knowing exact overload.
- **Default args**: OK on non-virtual with constant defaults. Not on virtual.
- **Trailing return types**: only when ordinary syntax impractical (complex templates).

---

## C++ Features

- **Smart pointers**: `unique_ptr` = exclusive. `shared_ptr` = shared. No `auto_ptr`.
- **Rvalue refs**: only for move ctor/assign, `*this`-consuming methods, perfect forwarding, perf overload pairs.
- **Exceptions**: **prohibited.** Use error codes + assertions.
- **`noexcept`**: use when accurate + useful. Required on move ctors for perf.
- **RTTI (`typeid`/`dynamic_cast`)**: avoid. Use virtual methods or visitor. OK in unit tests.
- **Casts**: C++-style only. `static_cast` for safe conversions. `absl::down_cast` for downcasts. `const_cast` to remove const. `reinterpret_cast` for unsafe pointer reinterpret. `std::bit_cast` for type punning. No C-style casts.
- **`nullptr`**: always. Never `NULL` or `0` for pointers.
- **`auto`**: use when type obvious from RHS. Avoid when return type opaque from name.
- **Braced init `{}`**: prefer. Prevents narrowing.
- **Lambdas**: OK for short concise callbacks. Complex logic → named function.
- **Integer types**: `int` default. Use `<cstdint>` types (`int32_t`, `uint64_t`) when bitwidth matters.
- **Macros**: avoid. Use `constexpr`, inline functions, enums. When required: `ALL_CAPS`.
- **`sizeof`**: prefer `sizeof(varname)` over `sizeof(type)`.
- **Boost**: use sparingly, prefer stdlib equivalents.

---

## Naming

| Thing | Convention | Example |
|---|---|---|
| Files | `lower_snake.cc` / `.h` | `my_file.cc` |
| Types (class/struct/enum/alias) | `UpperCamelCase` | `MyClass` |
| Variables (local) | `lower_snake` | `my_var` |
| Members (class) | `lower_snake_` (trailing `_`) | `my_member_` |
| Constants | `kUpperCamel` | `kDaysInWeek` |
| Functions | `lowerCamelCase` | `myFunction()` |
| Namespaces | `lower_snake` | `my_project` |
| Enumerators | `kEnumName` (or `EnumName` in scoped enums) | `kFoo` |
| Macros | `ALL_CAPS_UNDERSCORES` | `MY_MACRO` |

Accessors match member name without `_`: `count_` → `count()`.

---

## Comments

- `//` for single-line. `/* */` for multi-line (avoid per project rules — see SKILL.md).
- File-level comment: overview of contents.
- Class comment: what it does, how to use, thread-safety.
- Function comment: what, params, return, side effects, why (non-obvious).
- Variable comment: purpose if not obvious from name.
- `// TODO(username): description` for incomplete work.
- **Don't comment the obvious.** Comment the why, not the what.

---

## Formatting

- **Line length**: 80 chars max (hard limit; exceptions rare).
- **Indentation**: 2 spaces. No tabs.
- **Braces**: opening brace same line as statement. Function opening brace on new line.
- **Always brace**: `if`/`while`/`for` — even single-statement body.
- **Spaces**: around binary operators. After `if`/`while`/`for` keywords. Before `{`.
- **Pointers/refs**: attach to type: `int* p;` `int& r;`.
- **`return`**: no parens unless needed: `return result;` not `return (result);`.
- **Switch**: brace case blocks. `[[fallthrough]];` or comment on fall-through.
- **Namespace aliases**: OK in `.cc` / inside functions. Not in `.h` (except internal namespaces).

```cpp
// Brace style
if (condition) {
  DoSomething();
} else {
  DoSomethingElse();
}

void MyFunction() {
  // body
}
```

---

## Quick Don'ts

- No `using namespace X` at file scope.
- No exceptions.
- No RTTI in production code.
- No C-style casts.
- No `NULL`/`0` for null ptrs.
- No multiple implementation inheritance.
- No macros (when avoidable).
- No forward declarations (when avoidable).
- No virtual calls in constructors.
- No `auto_ptr`.
