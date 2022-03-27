/**
 * SPDX-FileCopyrightText: 2021 by Alexander Stippich <a.stippich@gmx.net>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "FilteredOptionsModel.h"
#include "OptionsModel.h"

FilteredOptionsModel::FilteredOptionsModel(QObject *parent) : QSortFilterProxyModel(parent)
{
}

FilteredOptionsModel::~FilteredOptionsModel() = default;

bool FilteredOptionsModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    const auto index = sourceModel()->index(source_row, 0, source_parent);
    const auto &state = sourceModel()->data(index, OptionsModel::StateRole).value<KSane::CoreOption::OptionState>();
    const auto &type = sourceModel()->data(index, OptionsModel::TypeRole).value<KSane::CoreOption::OptionType>();
    
    if (!m_showAllOptions) {
        return sourceModel()->data(index, OptionsModel::QuickAccessRole).toBool() && state == KSane::CoreOption::StateActive;
    }
    
    if (state != KSane::CoreOption::StateActive || type == KSane::CoreOption::TypeGamma || type == KSane::CoreOption::TypeDetectFail) {
        return false;
    }

    return true;
}

void FilteredOptionsModel::showAllOptions(bool show)
{
    if (m_showAllOptions != show) {
        m_showAllOptions = show;
        invalidateFilter();
    }
}
