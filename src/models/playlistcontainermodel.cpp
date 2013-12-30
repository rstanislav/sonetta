#include "playlistcontainermodel.h"

#include <QDebug>

namespace sp = Spotinetta;

namespace Sonetta {

PlaylistContainerModel::PlaylistContainerModel(ObjectSharedPointer<const Spotinetta::Session> session, QObject *parent)
    :   QAbstractListModel(parent), m_session(session),
      m_watcher(new sp::PlaylistContainerWatcher(session.data())),
      m_stateChangedMapper(new QSignalMapper),
      m_renamedMapper(new QSignalMapper),
      m_imageChangedMapper(new QSignalMapper),
      m_descriptionChangedMapper(new QSignalMapper)
{


    connect(m_watcher.data(), &sp::PlaylistContainerWatcher::loaded,
            this, &PlaylistContainerModel::onLoaded);
    connect(m_watcher.data(), &sp::PlaylistContainerWatcher::playlistAdded,
            this, &PlaylistContainerModel::onPlaylistAdded);
    connect(m_watcher.data(), &sp::PlaylistContainerWatcher::playlistMoved,
            this, &PlaylistContainerModel::onPlaylistMoved);
    connect(m_watcher.data(), &sp::PlaylistContainerWatcher::playlistRemoved,
            this, &PlaylistContainerModel::onPlaylistRemoved);

    connect(m_stateChangedMapper.data(), SIGNAL(mapped(int)),
            this, SLOT(onPlaylistStateChanged(int)));
    connect(m_renamedMapper.data(), SIGNAL(mapped(int)),
            this, SLOT(onPlaylistRenamed(int)));
    connect(m_imageChangedMapper.data(), SIGNAL(mapped(int)),
            this, SLOT(onPlaylistImageChanged(int)));
    connect(m_descriptionChangedMapper.data(), SIGNAL(mapped(int)),
            this, SLOT(onPlaylistDescriptionChanged(int)));
}

int PlaylistContainerModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_playlists.count();
}

QVariant PlaylistContainerModel::data(const QModelIndex &index, int role) const
{
    const sp::Playlist & playlist = m_playlists.at(index.row())->watched();

    switch (role)
    {
    case PlaylistRole:
        return QVariant::fromValue(playlist);
    case IsLoadedRole:
        return playlist.isLoaded();
    case IsValidRole:
        return playlist.isValid();
    case NameRole:
        return playlist.name();
    case DescriptionRole:
        return QString(); // Fix
    case ImageUriRole:
        return QString(); // Fix

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlaylistContainerModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(PlaylistRole, "playlist");
    roles.insert(IsLoadedRole, "isLoaded");
    roles.insert(IsValidRole, "isValid");
    roles.insert(NameRole, "name");
    roles.insert(DescriptionRole, "description");
    roles.insert(ImageUriRole, "imageUri");
    return roles;
}

sp::PlaylistContainer PlaylistContainerModel::playlistContainer() const
{
    return m_watcher->watched();
}

void PlaylistContainerModel::setPlaylistContainer(const Spotinetta::PlaylistContainer &container)
{
    if (container != playlistContainer())
    {
        beginResetModel();
        m_playlists.clear();
        endResetModel();
        m_watcher->watch(container);

        emit playlistContainerChanged();
    }
}

void PlaylistContainerModel::updateWatcherIndices(int first, int last)
{
    if (last >= first)
    {
        // last may be < first if a playlist is inserted into an empty container,
        // in which case we do not need to do anything in particular

        for (int i = first; i <= last; ++i)
        {
            auto watcher = m_playlists.at(i);
            updateMappings(watcher.data(), i);
        }
    }
}

ObjectSharedPointer<Spotinetta::PlaylistWatcher> PlaylistContainerModel::createWatcher(int index)
{
    const sp::Playlist playlist = playlistContainer().playlistAt(index);

    ObjectSharedPointer<sp::PlaylistWatcher> watcher(new sp::PlaylistWatcher(m_session.data()));

    connect(watcher.data(), SIGNAL(stateChanged()),
            m_stateChangedMapper.data(), SLOT(map()));
    connect(watcher.data(), SIGNAL(renamed()),
            m_renamedMapper.data(), SLOT(map()));
    connect(watcher.data(), SIGNAL(imageChanged()),
            m_imageChangedMapper.data(), SLOT(map()));
    connect(watcher.data(), SIGNAL(descriptionChanged()),
            m_descriptionChangedMapper.data(), SLOT(map()));

    updateMappings(watcher.data(), index);

    watcher->watch(playlist);
    return watcher;
}

void PlaylistContainerModel::updateMappings(Spotinetta::PlaylistWatcher *watcher, int index)
{
    m_stateChangedMapper->setMapping(watcher, index);
    m_renamedMapper->setMapping(watcher, index);
    m_imageChangedMapper->setMapping(watcher, index);
    m_descriptionChangedMapper->setMapping(watcher, index);
}

void PlaylistContainerModel::onLoaded()
{
    Q_ASSERT(!m_session.isNull());
    const sp::PlaylistContainer container = m_watcher->watched();

    if (container.playlistCount() > 0)
    {
        beginResetModel();
        m_playlists.reserve(container.playlistCount());

        for (int i = 0; i < container.playlistCount(); ++i)
        {
            m_playlists.append(createWatcher(i));
        }
        endResetModel();
    }
}

void PlaylistContainerModel::onPlaylistAdded(int position)
{
    beginInsertRows(QModelIndex(), position, position);

    m_playlists.insert(position, createWatcher(position));
    updateWatcherIndices(position + 1, m_playlists.count() - 1);

    endInsertRows();
}

void PlaylistContainerModel::onPlaylistRemoved(int position)
{
    beginRemoveRows(QModelIndex(), position, position);

    m_playlists.remove(position);
    updateWatcherIndices(position, m_playlists.count() - 1);

    endRemoveRows();
}

void PlaylistContainerModel::onPlaylistMoved(int oldPosition, int newPosition)
{
    beginMoveRows(QModelIndex(), oldPosition, oldPosition, QModelIndex(), newPosition);
    ObjectSharedPointer<sp::PlaylistWatcher> watcher = m_playlists.at(oldPosition);
    m_playlists.remove(oldPosition);
    m_playlists.insert(newPosition, watcher);

    updateWatcherIndices(oldPosition, newPosition);

    endMoveRows();
}

void PlaylistContainerModel::onPlaylistStateChanged(int position)
{
    // Update all roles for simplicity
    QModelIndex mi = index(position);
    emit dataChanged(mi, mi);
}

void PlaylistContainerModel::onPlaylistRenamed(int position)
{
    QModelIndex mi = index(position);
    emit dataChanged(mi, mi, QVector<int>(1, NameRole));
}

void PlaylistContainerModel::onPlaylistDescriptionChanged(int position)
{
    QModelIndex mi = index(position);
    emit dataChanged(mi, mi, QVector<int>(1, DescriptionRole));
}

void PlaylistContainerModel::onPlaylistImageChanged(int position)
{
    QModelIndex mi = index(position);
    emit dataChanged(mi, mi, QVector<int>(1, ImageUriRole));
}


}
