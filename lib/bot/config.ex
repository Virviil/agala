defmodule Agala.Bot.Config do
  @doc """
  Retrieves the compile time configuration for the bot.
  """
  @spec compile_config(:poller | :plug | :handler, bot :: Agala.Bot.t(), opts :: Keyword.t()) ::
          {atom, Agala.Provider.t(), Keyword.t()}
  def compile_config(mode, bot, opts) when mode in [:poller, :plug] do
    otp_app = Keyword.fetch!(opts, :otp_app)

    config =
      Application.get_env(otp_app, :external_cfg)
      |> case do
        nil ->
          Application.get_env(otp_app, bot, [])

        path ->
          {data, _} = Mix.Config.eval!(path)

          data[otp_app][bot]
          |> case do
            nil -> Application.get_env(otp_app, bot, [])
            res -> res
          end
      end

    config = Keyword.merge(opts, config) |> Keyword.put(:bot, bot) |> Enum.into(%{})

    # Provider checking section

    provider = config[:provider]

    unless provider do
      raise ArgumentError,
            "missing :provider configuration in " <> "config #{inspect(otp_app)}, #{inspect(bot)}"
    end

    unless Code.ensure_compiled?(provider) do
      raise ArgumentError,
            "provider #{inspect(provider)} was not compiled, " <>
              "ensure it is correct and it is included as a project dependency"
    end

    unless Agala.Provider in Agala.Util.behaviours_list(provider) do
      raise ArgumentError,
            "provider #{inspect(provider)} does not implement Agala.Provider behaviour, " <>
              "ensure it is correct and it is included as a module in the project"
    end

    # Chain checking section

    chain = config[:chain]

    unless chain do
      raise ArgumentError,
            "missing :chain configuration in " <> "config #{inspect(otp_app)}, #{inspect(bot)}"
    end

    unless Code.ensure_compiled?(chain) do
      raise ArgumentError,
            "chain #{inspect(chain)} was not compiled, " <>
              "ensure it is correct and it is included as a module in the project"
    end

    unless Agala.Chain in Agala.Util.behaviours_list(chain) do
      raise ArgumentError,
            "chain #{inspect(chain)} does not implement Agala.Chain behaviour, " <>
              "ensure it is correct and it is included as a module in the project"
    end

    {otp_app, provider, config}
  end
end
