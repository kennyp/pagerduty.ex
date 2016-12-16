# pagerduty.ex

A pagerduty client for Elixir

## Installation

The package can be installed as:

  1. Add `pagerduty` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pagerduty, "~> 2.0.0"}]
    end
    ```

  2. Ensure `pagerduty` is started before your application:

    ```elixir
    def application do
      [applications: [:pagerduty]]
    end
    ```

