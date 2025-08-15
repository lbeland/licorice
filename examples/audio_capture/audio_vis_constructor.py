import math

import matplotlib

matplotlib.use("Agg")

import librosa
import matplotlib.backends.backend_agg as agg
import matplotlib.pyplot as plt
import pygame
import scipy

pygame.display.init()


black = (0, 0, 0)
screen_width = 1280
screen_height = 1024
window = pygame.display.set_mode((screen_width, screen_height), pygame.DOUBLEBUF)
# window.fill(black)
screen = pygame.display.get_surface()

refresh_rate = 1 # ticks (20 ms)
# sprite_cursor = Circle(color_cursor, size_cursor[0], pos_cursor)
# sprite_target = Circle(color_target, size_target[0], pos_target)

# sprites = pygame.sprite.Group([sprite_cursor, sprite_target])

stft_window_size = 4096

fig = plt.figure(figsize=[4, 4], dpi=100)
ax = fig.gca()
ax.set_title('Power spectrogram')
ax.set_ylim((-200000, 200000))
