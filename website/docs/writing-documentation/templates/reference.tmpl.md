---
title: 'Markdown template: Reference topic'
---

Write a few sentences introducing the subject of this reference document (e.g., "This document lists the configuration
parameters for X component," or "The following are the command-line arguments for Y script.").

:::info If needed, use this syntax to add an informational note about how to use this reference material or important
overall considerations. :::

## [First Category of Reference Items, e.g., Configuration Parameters]

After a brief description of this section, list the reference items. Consider using a table for structured data or
definition lists for individual items.

### `parameter_one` (Example Item 1)

- **Description:** Detailed explanation of what `parameter_one` does.
- **Type:** `string`
- **Required:** Yes
- **Default:** `null`
- **Example:**

  ```yaml
  # In some_config.yaml
  parameter_one: 'value_for_one'
  ```

### `parameter_two` (Example Item 2)

- **Description:** Detailed explanation of what `parameter_two` does.
- **Type:** `boolean`
- **Required:** No
- **Default:** `false`
- **Example:**

  ```yaml
  # In some_config.yaml
  parameter_two: true
  ```

## [Second Category of Reference Items, e.g., Command-Line Arguments]

After a brief description of this section, list the items.

- **`--argument-alpha` | `-a`**

  - **Description:** Explanation of what this command-line argument controls.
  - **Accepts:** (e.g., string, path to a file)
  - **Example:**

    ```bash
    ./your_script.sh --argument-alpha "/path/to/input"
    ```

- **`--enable-beta-feature` | `-b`**
  - **Description:** Enables the experimental beta feature.
  - **Accepts:** N/A (boolean flag)
  - **Example:**

    ```bash
    ./your_script.sh --enable-beta-feature
    ```
