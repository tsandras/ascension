# Carousel Picker Component

A generic, reusable carousel picker component for Godot that allows users to navigate through a list of items using left/right navigation buttons.

## Features

- **Generic Design**: Can be used with any type of data (races, portraits, items, etc.)
- **Simple Navigation**: Left (◀) and right (▶) buttons for easy navigation
- **Flexible Data**: Works with arrays of dictionaries, objects, or simple values
- **Customizable**: Configurable item name key, sizes, and styling
- **State Management**: Maintains current selection and provides easy access to selected item

## Usage

### Basic Setup

```gdscript
# Create a carousel picker instance
var carousel = CarouselPicker.new()

# Create the UI with your data
var items = [
    {"name": "Item 1", "description": "First item"},
    {"name": "Item 2", "description": "Second item"},
    {"name": "Item 3", "description": "Third item"}
]

# Create the carousel UI
var carousel_container = carousel.create_carousel(items, "name", parent_container)
```

### Advanced Usage

```gdscript
# Custom item name key
var portraits = [
    {"id": 1, "display_name": "Portrait A", "path": "res://assets/portrait_a.png"},
    {"id": 2, "display_name": "Portrait B", "path": "res://assets/portrait_b.png"}
]

var portrait_carousel = CarouselPicker.new()
var container = portrait_carousel.create_carousel(portraits, "display_name", parent)

# Connect to selection changes
portrait_carousel.left_button.pressed.connect(_on_portrait_changed)
portrait_carousel.right_button.pressed.connect(_on_portrait_changed)
```

### Getting Selected Items

```gdscript
# Get the current item dictionary
var current_item = carousel.get_current_item()

# Get the current item name
var current_name = carousel.get_current_item_name()

# Get current item by specific key
var current_display_name = carousel.get_current_item_by_name("display_name")

# Get current index
var current_index = carousel.get_current_index()
```

### Navigation Control

```gdscript
# Set specific index
carousel.set_current_index(2)

# Find item by name and set it
var index = carousel.find_item_index_by_name("Human", "name")
if index >= 0:
    carousel.set_current_index(index)

# Check if carousel has items
if carousel.has_items():
    print("Carousel has %d items" % carousel.get_item_count())
```

## API Reference

### Methods

- `create_carousel(items_data: Array, item_name_key: String, container_parent: Control) -> Control`
  - Creates the carousel UI and returns the container
  - `items_data`: Array of items to display
  - `item_name_key`: Key to use for displaying item names
  - `container_parent`: Optional parent to add the carousel to

- `get_current_item() -> Dictionary`
  - Returns the currently selected item

- `get_current_item_name() -> String`
  - Returns the name of the currently selected item

- `get_current_item_by_name(name_key: String) -> String`
  - Returns the value of a specific key from the current item

- `get_current_index() -> int`
  - Returns the current selection index

- `set_current_index(index: int)`
  - Sets the current selection index and updates the display

- `find_item_index_by_name(item_name: String, name_key: String) -> int`
  - Finds the index of an item by its name/key value

- `set_items(new_items: Array, item_name_key: String)`
  - Updates the items in the carousel

- `has_items() -> bool`
  - Returns true if the carousel has any items

- `get_item_count() -> int`
  - Returns the total number of items

### Properties

- `current_index: int` - Current selection index
- `items: Array` - Array of all items
- `item_names: Array` - Array of item names for display
- `left_button: Button` - Left navigation button
- `right_button: Button` - Right navigation button
- `display_label: Label` - Center display label
- `container: Control` - Main carousel container

## Example: Race Selection

```gdscript
# In character creation
var race_carousel = CarouselPicker.new()

func generate_race_ui():
    var races = DatabaseManager.get_all_races()
    var container = race_carousel.create_carousel(races, "name", race_container)
    
    # Connect to selection changes
    race_carousel.left_button.pressed.connect(_on_race_changed)
    race_carousel.right_button.pressed.connect(_on_race_changed)
    
    # Set initial selection
    if races.size() > 0:
        _on_race_changed()

func _on_race_changed():
    var selected_race = race_carousel.get_current_item()
    if selected_race.has("name"):
        process_race_selection(selected_race.name)
```

## Styling

The carousel includes basic styling:
- Left/right buttons: 50x50 pixels with arrow symbols (◀ ▶)
- Center label: 200x50 pixels with centered text
- 10-pixel separation between elements
- Font size overrides for better visibility

You can customize the appearance by modifying the `create_carousel` method or by styling the returned container.
