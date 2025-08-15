if pygame.event.peek(eventtype=pygame.QUIT):
    pygame.quit()
    handle_exit(0)

if pNumTicks[0] % 10 == 0:

    history_signal = audio_signal_sourceRaw.ravel()[
        audio_signal_sourceBufVars[1] - stft_window_size :
        audio_signal_sourceBufVars[1]
    ].astype(np.float32)

    print(audio_signal_sourceRaw.ravel().shape, flush=True)
    print(audio_signal_sourceBufVars[9], flush=True)
    print(history_signal, flush=True)
    print(history_signal.shape, flush=True)

    # fft
    fft = scipy.fftpack.fft(history_signal)
    ax.plot(fft)

    # stft
    # stft = librosa.stft(history_signal)
    # stft_db = librosa.amplitude_to_db(stft)
    # # print(stft_db, flush=True)

    # img = librosa.display.specshow(
    #     stft_db,
    #     y_axis='log',
    #     x_axis='time',
    #     ax=ax
    # )

    # fig.colorbar(img, ax=ax, format="%+2.0f dB")

    canvas = agg.FigureCanvasAgg(fig)
    canvas.draw()
    renderer = canvas.get_renderer()
    raw_data = renderer.tostring_rgb()

    size = canvas.get_width_height()

    surf = pygame.image.fromstring(raw_data, size, "RGB")
    screen.blit(surf, (0,0))
    pygame.display.flip()
