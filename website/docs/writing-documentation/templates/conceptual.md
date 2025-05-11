---
title: Conceptual topic template guide
---

:::info **How to use this template guide**: This page explains the sections of the "Conceptual" topic template. To
create a new document using this template, start with the markdown version by copying the
[`conceptual.tmpl.md`](https://github.com/theepicsaxguy/homelab/blob/main/docs/docs/templates/conceptual.tmpl.md) file
from the GitHub repository or by downloading it:

```bash
wget https://raw.githubusercontent.com/theepicsaxguy/homelab/main/docs/docs/templates/conceptual.tmpl.md -O your-conceptual-topic-name.md
```

Edit your new markdown file, referring to this page for descriptions of each section. You can build out a "stub file"
with just headers, then gradually add content. Use screenshots sparingly. Refer to our
[Documentation style guide](../style-guide.mdx) for writing tips and project-specific rules. :::

Use a title that focuses on the feature, component, or technology you are writing about. For conceptual documents, the
title should clearly indicate a concept, such as "About [Feature X]," "Overview of [Component Y]," or "Understanding
[Technology Z]."

In the first section, immediately after the title (with no H2 heading), write one or two sentences providing a brief
introduction to the feature, component, or technology being discussed. The following sections can help break down the
content logically.

## Common use cases (Optional Section)

In this optional section, provide some example use cases for the feature or component within the context of this homelab
project. Explain _why_ and in what scenarios a user might employ it. If you mention _how_ to use the feature, ensure you
link to any related procedural documentation. You can also share situations where the feature might _not_ be suitable or
has limitations.

## Overview of [Feature/Component/Technology]

Dive deeper into explaining the core concepts behind the feature, component, or technology.

Write from the user's perspective: What problem does this solve? Why should they consider using it (or understand it)?
Are there specific situations where it is particularly beneficial or, conversely, where it should be avoided or used
with caution?

:::info If you find yourself writing extensive "how-to" steps here, that content might be better suited for a separate
procedural topic or a "Combination" topic. Conceptual topics should focus on the "what" and "why." :::

Cover any essential background information the user needs to know. If there are related reference documents or
procedural guides for this subject, be sure to link to them from this page to provide a complete picture.

## Important considerations

List anything that is critical for the user to be aware of. This might include:

- Situations where this feature might not be the ideal solution.
- Necessary pre-configurations or dependencies that must be in place.
- Potential limitations, caveats, or trade-offs.
- Security implications.
